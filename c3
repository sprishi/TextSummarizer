import pandas as pd
from bokeh.io import curdoc
from bokeh.layouts import column, row
from bokeh.models import ColumnDataSource, DataTable, TableColumn, DateFormatter, NumberFormatter, Select, DateRangeSlider
from dataiku import Dataset

# Read the prepared data from Dataiku
data = Dataset("Prepared_Data").get_dataframe()

# Reshape the data to the desired format
reshaped_data = data.melt(id_vars=["Model_Date", "Load_Region"], value_vars=["Total", "Positive", "Negative"], var_name="Case_Type", value_name="Count")
reshaped_data = reshaped_data.sort_values(by=["Model_Date", "Load_Region", "Case_Type"], ascending=[False, False, True])
reshaped_data = reshaped_data.reset_index(drop=True)

# Create the ColumnDataSource
source = ColumnDataSource(reshaped_data)

# Define the columns for the DataTable
columns = [
    TableColumn(field="Model_Date", title="Date", formatter=DateFormatter(), sortable=False),
    TableColumn(field="Case_Type", title="", formatter=NumberFormatter(), sortable=False),
] + [
    TableColumn(field=country, title=country, formatter=NumberFormatter(), sortable=False)
    for country in data["Load_Region"].unique()
]

# Create the DataTable
data_table = DataTable(source=source, columns=columns, width=1200, height=500, index_position=None)

# Create the country filter
countries = sorted(data["Load_Region"].unique())
country_filter = Select(title="Country Filter", value="All", options=["All"] + countries)

# Create the date range slider
date_range_slider = DateRangeSlider(
    title="Date Range",
    value=(data["Model_Date"].min(), data["Model_Date"].max()),
    start=data["Model_Date"].min(),
    end=data["Model_Date"].max()
)

# Update the data source based on filter selections
def update_source():
    view = source.data

    # Filter by country
    selected_country = country_filter.value
    if selected_country != "All":
        view = view[view["Load_Region"] == selected_country]

    # Filter by date range
    date_range = date_range_slider.value
    view = view[
        (view["Model_Date"] >= date_range[0]) & (view["Model_Date"] <= date_range[1])
    ]

    source.data = view

# Add callbacks to update the data source
country_filter.on_change("value", lambda attr, old, new: update_source())
date_range_slider.on_change("value", lambda attr, old, new: update_source())

# Create the layout
layout = column(
    row(country_filter, date_range_slider),
    data_table
)

# Add the layout to the Bokeh document
curdoc().add_root(layout)
curdoc().title = "COVID-19 Data Visualization"
