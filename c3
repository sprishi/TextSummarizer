import dataiku
import pandas as pd
from bokeh.models import ColumnDataSource, DataTable, TableColumn
from bokeh.layouts import layout
from bokeh.io import curdoc

# Load the dataset
dataset = dataiku.Dataset("your_dataset_name")
df = dataset.get_dataframe()

# Convert DataFrame to ColumnDataSource
source = ColumnDataSource(df)

# Define columns for DataTable
columns = [TableColumn(field=col, title=col) for col in df.columns]

# Create DataTable with dynamic sizing
data_table = DataTable(source=source, columns=columns, sizing_mode='stretch_both')

# Layout the table
l = layout([[data_table]], sizing_mode='stretch_both')

# Add the layout to the current document
curdoc().add_root(l)
