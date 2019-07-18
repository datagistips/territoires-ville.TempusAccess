import datetime as dt
import pandas as pd
import matplotlib.pyplot as plt
from display_calendar_fxns import plot_calendar, get_date_time, get_dates_between

def display_calendar_for_gtfs(gtfs_dir):
	
	# CALENDAR DATES
	df = pd.read_csv(gtfs_dir + "calendar.txt")

	# ADD COLOR COLUMN
	N = df.shape[0]
	cmap = plt.cm.get_cmap("hsv", N+1)
	df["color"] = [cmap(i) for i in range(0, N)]

	# EXCEPTIONS
	df_exception = pd.read_csv(gtfs_dir + "calendar_dates.txt")

	# PROCESS DATA FRAME ROW BY ROW
	days = list()
	months = list()
	service_ids = list()
	colors = list()
	week_ends = list()

	for i in range(0, df.shape[0]):
		
		# get service
		service_id = df.iloc[i]["service_id"]
		
		# get row
		start = get_date_time(df.iloc[i].loc["start_date"])
		end = get_date_time(df.iloc[i].loc["end_date"])
		
		# color
		color = df.iloc[i].loc["color"]
		
		# period dates
		dates = get_dates_between(start, end)
		
		# weekdays_to_exclude
		weekdays_to_exclude = [index for index in range(1,8) if df.iloc[i, index] != 1]
		dates = [elt for elt in dates if elt.weekday() not in weekdays_to_exclude]

		# exception dates
		exception_dates = [get_date_time(elt) for elt in df_exception[df_exception["service_id"] == service_id]["date"].astype(str)]
		dates = [elt for elt in dates if elt not in exception_dates]
		
		# days
		dates = [elt for elt in dates if elt.weekday() not in weekdays_to_exclude]
			
		# days and months
		for elt in dates:
			days.append(int(elt.strftime("%d")))
			months.append(int(elt.strftime("%m")))
			service_ids.append(service_id)
			colors.append(color)
			# is week-end ?
			week_ends.append(elt.weekday() > 4)

	# calculate calendar plot
	my_plot = plot_calendar(days, months, colors, week_ends)
	# ~ my_plot.show()
	
	# return plot
	return(my_plot)
