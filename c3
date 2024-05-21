import dataiku
import pandas as pd
from bokeh.models import ColumnDataSource, DataTable, TableColumn, HTMLTemplateFormatter
from bokeh.layouts import layout
from bokeh.io import curdoc
from bokeh.models.widgets import NumberFormatter

# Load the dataset
dataset = dataiku.Dataset("your_dataset_name")
df = dataset.get_dataframe()

# Prepare the DataFrame to simulate row merging for the Date column
df['Display_Date'] = df['Date']
df.loc[df['Date'].duplicated(), 'Display_Date'] = ''

# Convert DataFrame to ColumnDataSource
source = ColumnDataSource(df)

# Define a template for conditional formatting
header_color_template = """
    <div style="background-color: #f0f0f0; color: #333; font-weight: bold;">
        <%= value %>
    </div>
"""

second_column_color_template = """
    <div style="color: #ff5733;">
        <%= value %>
    </div>
"""

# Define columns for DataTable with conditional formatting
columns = [
    TableColumn(field="Display_Date", title="Date", formatter=HTMLTemplateFormatter(template=header_color_template)),
    TableColumn(field="second_column_name", title="Second Column", formatter=HTMLTemplateFormatter(template=second_column_color_template)),
]

# Add other columns without special formatting
for col in df.columns:
    if col not in ["Date", "Display_Date", "second_column_name"]:
        columns.append(TableColumn(field=col, title=col))

# Create DataTable with dynamic sizing
data_table = DataTable(source=source, columns=columns, sizing_mode='stretch_both')

# Layout the table
l = layout([[data_table]], sizing_mode='stretch_both')

# Add the layout to the current document
curdoc().add_root(l)
