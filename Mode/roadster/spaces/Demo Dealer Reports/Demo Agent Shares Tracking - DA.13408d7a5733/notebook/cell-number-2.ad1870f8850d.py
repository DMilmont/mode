from plotly.offline import download_plotlyjs, init_notebook_mode, iplot
from plotly.graph_objs import *
import plotly
plotly.offline.init_notebook_mode()
import pandas as pd

df = datasets[0]

trace1 = Bar(
    x=df.date,
    y=df.agent_shares,
     marker = dict(color='#03367c'),
    name='Agent Shares'
)
trace2 = Scatter(
    x=df.date,
    y=df.shares_opened_perc,
    marker = dict(color='#95aa1f'),
    name='Shares Opened %',
    yaxis='y2'
)

trace3 = Scatter(
    x=df.date,
    y=df.shares_clicked_perc,
    marker = dict(color='#27825c'),
    name='Shares Clicked %',
    yaxis='y2'
)
data = [trace1, trace2, trace3]
layout = Layout(

    legend=dict(
      orientation="h",
      xanchor="auto"
    ),
    width= 1000,
    height= 450,
    xaxis = {
   'tickformat': '%a %b %d',
   'tickmode': 'auto',
},
    
    yaxis=dict(
        title='Agent Shares',
     #   range=[0,df['agent_shares'].max() + .1*df['agent_shares'].max() ],
        showgrid=False,
        showline=False,
        dtick=round(df['agent_shares'].max() / 5),
    rangemode='tozero',
    ),
    yaxis2=dict(
   
        titlefont=dict(
            color='rgb(148, 103, 189)'
        ),
        tickfont=dict(
            color='rgb(148, 103, 189)'
        ),
        tickformat="%",
        overlaying='y',
        range=[0,1],
        side='right',
        showgrid=False,
        showline=False,
        rangemode='tozero',
    )
    
)

fig = dict(data=data, layout=layout)
iplot(fig)