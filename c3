import pandas as pd
import torch
from sklearn.metrics.pairwise import cosine_similarity
from transformers import AutoTokenizer, AutoModelForMaskedLM, Trainer, TrainingArguments

# Model selection
MODEL_NAME = 'microsoft/MiniLM-L12-H384-uncased'
# Uncomment the following lines to switch models
# MODEL_NAME = 'bert-base-uncased'
# MODEL_NAME = 'roberta-base'

# Load tokenizer and model
tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)
model = AutoModelForMaskedML.from_pretrained(MODEL_NAME)

# Load the locode data
locode_df = pd.read_csv('locode_data.csv')

# Fill NA values with empty strings
locode_df.fillna('', inplace=True)

# Combine relevant columns into a single string for each row with weights
locode_df['combined'] = locode_df.apply(
    lambda x: ' '.join([
        f"{x['country_code']} " * 2,
        f"{x['country_name']} " * 2,
        f"{x['location_code']} " * 3,
        f"{x['location_name']} " * 3,
        f"{x['sub_division_code']} " * 1,
        f"{x['sub_division_name']} " * 1,
        f"{x['sub_division_type']} " * 1
    ]), axis=1)

# Prepare the dataset for fine-tuning
locode_texts = locode_df['combined'].tolist()
inputs = tokenizer(locode_texts, return_tensors='pt', max_length=128, truncation=True, padding=True)

class LocodeDataset(torch.utils.data.Dataset):
    def __init__(self, encodings):
        self.encodings = encodings
    
    def __getitem__(self, idx):
        return {key: torch.tensor(val[idx]) for key, val in self.encodings.items()}
    
    def __len__(self):
        return len(self.encodings['input_ids'])

dataset = LocodeDataset(inputs)

# Set up training arguments for fine-tuning
training_args = TrainingArguments(
    output_dir='./results',          
    num_train_epochs=3,              
    per_device_train_batch_size=8,  
    save_steps=10_000,               
    save_total_limit=2,             
)

# Initialize the Trainer for fine-tuning
trainer = Trainer(
    model=model,                         
    args=training_args,                  
    train_dataset=dataset,         
)

# Train the model
trainer.train()

# Save the fine-tuned model
model.save_pretrained('/path/to/save/fine_tuned_model')
tokenizer.save_pretrained('/path/to/save/fine_tuned_model')

# Load the fine-tuned model for similarity search
fine_tuned_model = AutoModelForMaskedLM.from_pretrained('/path/to/save/fine_tuned_model')
fine_tuned_tokenizer = AutoTokenizer.from_pretrained('/path/to/save/fine_tuned_model')

def get_embeddings(text):
    inputs = fine_tuned_tokenizer(text, return_tensors='pt', truncation=True, padding=True, max_length=128)
    outputs = fine_tuned_model(**inputs)
    return outputs.last_hidden_state.mean(dim=1).detach().numpy()

# Load the AIS data
ais_df = pd.read_csv('ais_data.csv')

# Preprocess AIS destinations
ais_df['preprocessed_destination'] = ais_df['AIS_destination']

# Function to find the most similar row in locode data after preprocessing
def find_most_similar(preprocessed_destination):
    destination_embedding = get_embeddings(preprocessed_destination).squeeze()
    locode_df['similarity'] = locode_df['combined'].apply(lambda x: cosine_similarity([destination_embedding], [get_embeddings(x).squeeze()])[0][0])
    most_similar_row = locode_df.loc[locode_df['similarity'].idxmax()]
    return most_similar_row[['country_code', 'country_name', 'location_code', 'location_name', 'sub_division_code', 'sub_division_name', 'sub_division_type']]

# Apply the function to each preprocessed AIS destination and store results
ais_df['most_similar_locode'] = ais_df['preprocessed_destination'].apply(find_most_similar)

# Print the results for verification
print(ais_df[['AIS_destination', 'preprocessed_destination', 'most_similar_locode']])

# Save the results
ais_df.to_csv('ais_similarity_results.csv', index=False)







================================================

import streamlit as st
import pandas as pd
import dataiku
from streamlit_cookies_manager import EncryptedCookieManager

# This needs to be called once, and must be called immediately after streamlit imports.
cookie_manager = EncryptedCookieManager(
    prefix="my_app/",  # Define a cookie prefix
    password="YourPasswordHere"  # Define a password
)

# Load cookies
cookie_manager.load()

# Fetch the datasets
df1 = dataiku.Dataset("df1").get_dataframe().fillna('')
df2 = dataiku.Dataset("df2").get_dataframe().fillna('')

# Extract column names for filtering
filter_columns = df1.columns[2:]

# Function to convert numeric columns to integers
def convert_to_int(df):
    for col in df.select_dtypes(include=['float64']).columns:
        df[col] = pd.to_numeric(df[col], errors='coerce').fillna(0).astype('Int64')
    return df

# Convert relevant columns in df1 and df2 to integers
df1 = convert_to_int(df1)
df2 = convert_to_int(df2)

# Function to create a custom HTML table with merged cells
def create_custom_table(df):
    # Reset the index to remove it
    df = df.reset_index(drop=True)
    
    # Create an empty list to store rows
    rows = []
    for i, row in df.iterrows():
        # If the date is the same as the previous row, set it to an empty string
        if i > 0 and df.iloc[i, 0] == df.iloc[i-1, 0]:
            row[0] = ''
        rows.append(row)

    # Create HTML for the table
    html = '<table border="1" width="100%">'
    html += '<thead><tr>' + ''.join([f'<th>{col}</th>' for col in df.columns]) + '</tr></thead>'
    html += '<tbody>'
    for row in rows:
        html += '<tr>' + ''.join([f'<td>{value}</td>' for value in row]) + '</tr>'
    html += '</tbody></table>'
    
    return html

# Set page configuration for wider layout
st.set_page_config(layout="wide")

# Function to check login credentials
def check_login(username, password):
    # Replace with your actual username and password check
    return username == "admin" and password == "password"

# Function to display login page
def login_page():
    st.title("Login")
    username = st.text_input("Username")
    password = st.text_input("Password", type="password")
    if st.button("Login"):
        if check_login(username, password):
            cookie_manager["logged_in"] = "True"
            cookie_manager.save()
            st.experimental_rerun()
        else:
            st.error("Invalid username or password")

# Function to display the main application
def main_page():
    st.title("Data Viewer")
    if st.button("Logout"):
        cookie_manager["logged_in"] = "False"
        cookie_manager.save()
        st.experimental_rerun()

    tab1, tab2 = st.tabs(["Model Hit/Fail Metric", "Marcopolo Metric"])

    with tab1:
        selected_columns = st.multiselect(
            "Select columns to display",
            options=filter_columns,
            default=list(filter_columns)
        )

        if selected_columns:
            filtered_df1 = df1[[df1.columns[0]] + selected_columns]
        else:
            filtered_df1 = df1
        
        st.markdown(create_custom_table(filtered_df1), unsafe_allow_html=True)

    with tab2:
        st.markdown(df2.style.hide_index().set_table_attributes('class="dataframe"').render(), unsafe_allow_html=True)

# Check login status using cookies
if cookie_manager.get("logged_in") == "True":
    main_page()
else:
    login_page()


=======


