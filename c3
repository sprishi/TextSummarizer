import dataiku
import pandas as pd
from bokeh.models import ColumnDataSource, DataTable, TableColumn
from bokeh.layouts import layout
from bokeh.embed import components
from bokeh.resources import INLINE

# Load the dataset
dataset = dataiku.Dataset("your_dataset_name")
df = dataset.get_dataframe()

# Convert DataFrame to ColumnDataSource
source = ColumnDataSource(df)

# Define columns for DataTable
columns = [TableColumn(field=col, title=col) for col in df.columns]

# Create DataTable
data_table = DataTable(source=source, columns=columns, width=800, height=280)

# Layout the table
l = layout([[data_table]])

# Embed the plot in the webapp
script, div = components(l)

# Generate the HTML to display the table
html = f"""
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Dataiku Bokeh Webapp</title>
    {INLINE.render()}
</head>
<body>
    {div}
    <script type="text/javascript">
        {script}
    </script>
</body>
</html>
"""

# Display the HTML in the webapp
display_html(HTML)

