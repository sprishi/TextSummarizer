# Create a Bokeh plot
p = figure(title="Sample Bokeh Plot", x_axis_label='X', y_axis_label='Y')
p.line(df['x'], df['y'], legend_label='Line', line_width=2)

script, div = components(p)

# Generate the HTML to display the plot
html = f"""
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Dataiku Bokeh Webapp</title>
    <link rel="stylesheet" href="https://cdn.bokeh.org/bokeh/release/bokeh-2.4.2.min.css" type="text/css" />
    <script type="text/javascript" src="https://cdn.bokeh.org/bokeh/release/bokeh-2.4.2.min.js"></script>
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
display_html(html)
