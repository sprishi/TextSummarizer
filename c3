# Add the 'Total till date' row
total_till_date = df.groupby('Load_Region').agg({'Total': 'sum', 'Positive': 'sum', 'Negative': 'sum'}).T
total_till_date['Model_Date'] = 'Total till date'
total_till_date = total_till_date.reset_index().rename(columns={'index': 'Hit_Fail_Status'})

# Reformatting the total_till_date to match the result DataFrame structure
total_till_date = total_till_date.melt(id_vars=['Model_Date', 'Hit_Fail_Status'], var_name='Load_Region', value_name='Count')
total_till_date = total_till_date.pivot(index=['Model_Date', 'Hit_Fail_Status'], columns='Load_Region', values='Count').reset_index()
total_till_date.columns = ['_'.join(col).strip() for col in total_till_date.columns.values]
total_till_date.columns = total_till_date.columns.str.replace('Model_Date_', 'Model_Date').str.replace('Hit_Fail_Status_', 'Hit_Fail_Status')

# Concatenating the total_till_date rows with the result DataFrame
final_df = pd.concat([total_till_date, result], axis=0)

# Sorting the final DataFrame
final_df.sort_values(by='Model_Date', ascending=False, inplace=True)




--------------=================


import pandas as pd
from bokeh.models import ColumnDataSource, DataTable, TableColumn, Dropdown, Slider
from bokeh.layouts import column, row
from bokeh.plotting import curdoc
from bokeh.transform import factor_cmap

# Load the prepared data
df = pd.read_csv("prepared_data.csv")

# Convert DataFrame to ColumnDataSource
source = ColumnDataSource(df)

# Define the columns for the DataTable
columns = [
    TableColumn(field="Model_Date", title="Model_Date"),
    TableColumn(field="Hit_Fail_Status", title="Hit_Fail_Status")
]

# Additional columns for each country
countries = [col.split('_')[1] for col in df.columns if '_' in col]
for country in set(countries):
    columns.append(TableColumn(field=f"Total_{country}", title=f"Total {country}"))
    columns.append(TableColumn(field=f"Positive_{country}", title=f"Positive {country}"))
    columns.append(TableColumn(field=f"Negative_{country}", title=f"Negative {country}"))

# Create DataTable
data_table = DataTable(source=source, columns=columns, width=1000, height=800)

# Filter features
country_filter = Dropdown(label="Select Country", menu=countries)
date_slider = Slider(start=1, end=len(df), value=1, step=1, title="Select Date Range")

# Filter callback
def update():
    selected_country = country_filter.value
    date_range = date_slider.value
    filtered_df = df[(df['Model_Date'] <= date_range) & (df['Load_Region'] == selected_country)]
    source.data = ColumnDataSource(filtered_df).data

country_filter.on_change('value', lambda attr, old, new: update())
date_slider.on_change('value', lambda attr, old, new: update())

# Layout
layout = column(row(country_filter, date_slider), data_table)

# Add to document
curdoc().add_root(layout)
curdoc().title = "Covid-19 Data Visualization"
