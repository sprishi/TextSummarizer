import streamlit as st
import pandas as pd
import dataiku

# Fetch the datasets
df1 = dataiku.Dataset("df1").get_dataframe().fillna('')
df2 = dataiku.Dataset("df2").get_dataframe().fillna('')

# Extract column names for filtering
filter_columns = df1.columns[2:]

# Function to convert numeric columns to integers
def convert_to_int(df):
    for col in df.select_dtypes(include=['float64']).columns:
        df[col] = pd.to_numeric(df[col], errors='coerce').fillna(0).astype(int)
    return df

# Convert relevant columns in df1 and df2 to integers
df1 = convert_to_int(df1)
df2 = convert_to_int(df2)

# Function to create a custom HTML table with merged cells
def create_custom_table(df):
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

# App layout
st.title("Data Viewer")

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
    
    st.markdown(create_custom_table(filtered_df1.reset_index(drop=True)), unsafe_allow_html=True)

with tab2:
    st.dataframe(df2.reset_index(drop=True), use_container_width=True)




==============================================

import dash
import dash_table
import dash_core_components as dcc
import dash_html_components as html
from dash.dependencies import Input, Output
import pandas as pd
import dataiku

# Fetch the datasets
df1 = dataiku.Dataset("df1").get_dataframe().fillna('')
df2 = dataiku.Dataset("df2").get_dataframe().fillna('')

# Initialize the Dash app
app = dash.Dash(__name__)

# Extract column names for filtering
filter_columns = df1.columns[2:]

app.layout = html.Div([
    dcc.Tabs([
        dcc.Tab(label='Model Hit/Fail Metric', children=[
            dcc.Dropdown(
                id='column-filter',
                options=[{'label': col, 'value': col} for col in filter_columns],
                multi=True,
                placeholder="Select columns to display"
            ),
            dcc.DatePickerRange(
                id='date-picker-range',
                start_date=df1[df1.columns[0]].min(),
                end_date=df1[df1.columns[0]].max(),
                display_format='YYYY-MM-DD',
                start_date_placeholder_text='Start Date',
                end_date_placeholder_text='End Date'
            ),
            dash_table.DataTable(
                id='table1',
                columns=[{"name": i, "id": i} for i in df1.columns],
                data=df1.to_dict('records'),
                style_table={'height': 'auto', 'overflowY': 'auto'},
                style_cell={'minWidth': '150px', 'width': '150px', 'maxWidth': '150px', 'whiteSpace': 'normal'}
            )
        ]),
        dcc.Tab(label='Marcopolo Metric', children=[
            dash_table.DataTable(
                id='table2',
                columns=[{"name": i, "id": i} for i in df2.columns],
                data=df2.to_dict('records'),
                style_table={'height': 'auto', 'overflowY': 'auto'},
                style_cell={'minWidth': '150px', 'width': '150px', 'maxWidth': '150px', 'whiteSpace': 'normal'}
            )
        ])
    ])
])

@app.callback(
    Output('table1', 'columns'),
    Output('table1', 'data'),
    Input('column-filter', 'value'),
    Input('date-picker-range', 'start_date'),
    Input('date-picker-range', 'end_date')
)
def update_table(selected_columns, start_date, end_date):
    filtered_df = df1[(df1[df1.columns[0]] >= start_date) & (df1[df1.columns[0]] <= end_date)]
    if selected_columns:
        columns = [{"name": i, "id": i} for i in [df1.columns[0]] + selected_columns]
        data = filtered_df[[df1.columns[0]] + selected_columns].to_dict('records')
    else:
        columns = [{"name": i, "id": i} for i in df1.columns]
        data = filtered_df.to_dict('records')
    return columns, data

if __name__ == '__main__':
    app.run_server(debug=True)


"""



import streamlit as st
import pandas as pd
import dataiku

# Fetch the datasets
df1 = dataiku.Dataset("df1").get_dataframe().fillna('')
df2 = dataiku.Dataset("df2").get_dataframe().fillna('')

# Extract column names for filtering
filter_columns = df1.columns[2:]

# App layout
st.title("Data Viewer")

tab1, tab2 = st.tabs(["Model Hit/Fail Metric", "Marcopolo Metric"])

with tab1:
    selected_columns = st.multiselect(
        "Select columns to display",
        options=filter_columns,
        default=filter_columns
    )
    start_date, end_date = st.date_input(
        "Select date range",
        value=[df1[df1.columns[0]].min(), df1[df1.columns[0]].max()],
        min_value=df1[df1.columns[0]].min(),
        max_value=df1[df1.columns[0]].max()
    )
    filtered_df1 = df1[(df1[df1.columns[0]] >= start_date) & (df1[df1.columns[0]] <= end_date)]
    if selected_columns:
        st.dataframe(filtered_df1[[df1.columns[0]] + selected_columns])
    else:
        st.dataframe(filtered_df1)

with tab2:
    st.dataframe(df2)


 
