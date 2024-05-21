from bokeh.io import show
from bokeh.models import ColumnDataSource, DataTable, TableColumn, Panel, Tabs, MultiSelect, CustomJS
from bokeh.layouts import layout, column
from bokeh.io import curdoc
import pandas as pd

# Sample dataframe
data1 = {
    'Region': ['North', 'South', 'East', 'West'],
    'Product': ['A', 'B', 'C', 'D'],
    'Sales': [100, 200, 300, 400],
    'Profit': [10, 20, 30, 40]
}

df1 = pd.DataFrame(data1)

# Columns for filtering (index 2 and onwards)
filter_columns = df1.columns[2:]

# Convert dataframe to ColumnDataSource
source1 = ColumnDataSource(df1)

# Define columns for DataTable
all_columns = [TableColumn(field=col, title=col) for col in df1.columns]

# Create DataTable
data_table1 = DataTable(source=source1, columns=all_columns, sizing_mode='stretch_both')

# Create MultiSelect widget for column filtering
multi_select = MultiSelect(title="Select Columns", value=list(filter_columns), options=list(filter_columns))

# Create a callback to update the DataTable based on MultiSelect
callback = CustomJS(args=dict(source=source1, data_table=data_table1, columns=all_columns, multi_select=multi_select), code="""
    var selected = multi_select.value;
    var columns = [];
    // Always include 'Region' and 'Product' columns
    columns.push(columns[0]);
    columns.push(columns[1]);
    for (var i = 0; i < selected.length; i++) {
        for (var j = 0; j < columns.length; j++) {
            if (columns[j].field == selected[i]) {
                columns.push(columns[j]);
            }
        }
    }
    data_table.columns = columns;
""")

multi_select.js_on_change('value', callback)

# Create a layout with the MultiSelect and DataTable
layout1 = column(multi_select, data_table1)

# Create panel for the first dataframe
panel1 = Panel(child=layout1, title="DataFrame 1")

# Sample data for the second dataframe
data2 = {'name': ['David', 'Eve', 'Frank'], 'age': [30, 28, 25]}
df2 = pd.DataFrame(data2)
source2 = ColumnDataSource(df2)
columns2 = [TableColumn(field=col, title=col) for col in df2.columns]
data_table2 = DataTable(source=source2, columns=columns2, sizing_mode='stretch_both')
panel2 = Panel(child=data_table2, title="DataFrame 2")

# Create tabs
tabs = Tabs(tabs=[panel1, panel2])

# Add the tabs to the root layout with responsive sizing mode
root_layout = layout([[tabs]], sizing_mode='stretch_both')

# Show the layout (for testing outside Dataiku, in a standalone script)
# show(layout)

# For Dataiku, add layout to curdoc
curdoc().add_root(root_layout)
