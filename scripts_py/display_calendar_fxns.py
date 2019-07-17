# https://glowingpython.blogspot.com/2018/06/plotting-calendar-in-matplotlib.html
import calendar
import numpy as np
from matplotlib.patches import Rectangle
import matplotlib.pyplot as plt
import datetime as dt


def plot_calendar(days, months, colors, week_ends):
		
	plt.figure(figsize=(9, 3))

	ax = plt.gca().axes

	for d, m, c, we in zip(days, months, colors, week_ends):
		ec = None if we is False else '0.8'
		ax.add_patch(Rectangle((d, m), width=.8, height=.8, facecolor=c, edgecolor=ec, linewidth=2))
    
	plt.yticks(np.arange(1, 13)+.5, list(calendar.month_abbr)[1:])
	plt.xticks(np.arange(1,32)+.5, np.arange(1,32))
	plt.xlim(1, 32)
	plt.ylim(1, 13)
	plt.gca().invert_yaxis()
	# remove borders and ticks
	for spine in plt.gca().spines.values():
		spine.set_visible(False)
	plt.tick_params(top=False, bottom=False, left=False, right=False)
	# ~ plt.show()
   
	return(plt)
    
def get_date_time(date_start):
		
	date_start = str(date_start)
	
	year = int(date_start[0:4])
	month = int(date_start[4:6])
	day = int(date_start[6:8])

	date_start = dt.datetime(year, month, day)
	
	return(date_start)
	
# dates between start and end
def get_dates_between(start, end):
	
	# delta
	delta = end - start
	dates =  [start + dt.timedelta(days=i) for i in range(delta.days + 1)]
	
	return(dates)
