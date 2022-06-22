#!/usr/bin/env python
#This script creates synthetic QPE fields by moving the origin coordinates of the original QPE field
import Queue as qu
import numpy as np
from threading import Thread
import os
import subprocess as sp
import datetime as dt

# Function to send error emails
def mail(to, subject, text):
        sp.call('echo "' + text + '" | mail -s "' + subject + '" ' + to, shell=True)

def worker():
        while True:
                #Obtain string array of filenames and folders 
                inArgs = qu.get()

		#Testing command
		print("gdal_edit.py -a_ullr " +  inArgs[0] + " " + inArgs[1] + " " + inArgs[2] + " " + inArgs[3] + " " + inArgs[4])

		#System calls to execute command		
		sp.call("gdal_edit.py -a_ullr " +  inArgs[0] + " " + inArgs[1] + " " + inArgs[2] + " " + inArgs[3] + " " + inArgs[4], shell=True) 

                #Complete worker's task
                qu.task_done()


#Initiate Queue and Workers
qu = qu.Queue()
numworkers = 8
for i in range(numworkers):
        t = Thread(target=worker)
        t.daemon = True
        t.start()

#Type of perturbation: steady_state or dynamic
pert_type = 'steady_state'
disp_length = 25

#Date of starting cycle
start_date = dt.datetime(2018,5,27,19,0,0) 
delta_t = dt.timedelta(minutes=20)

#period @ 10-min 18 hours out from date of starting cycle
end_date = start_date + dt.timedelta(hours=14) 

print('Working on ' + start_date.strftime("%Y%m%d_%H%M") + ' to ' + end_date.strftime("%Y%m%d_%H%M")) 

#Spatial parameters
origin_lat = 55 
origin_lon = -130 
ulx = -130 
uly = 55 
lrx = -60 
lry = 20 
xres = 0.01
yres = -0.01

#Folder to store ensemble of synthetic QPEs
experiment_folder = 'QPEperturbations/' + pert_type  + '/disp' + str(disp_length) + 'km/'

#Read in new origins to create synthetic fields
#latitude,longitude,distance(km),direction angle(degrees)
perturbation_file = 'QPEperturbations/' + pert_type  + '/origin_round_form_distance_enforced_' + str(disp_length) + 'km.csv'
displaced_origins = np.loadtxt(perturbation_file, dtype='float', delimiter=',', skiprows=1)

#Number of origins, which will be used to create an ensemble
ensemble_sz = np.shape(displaced_origins)[0]

#Create folders to store synthetic QPEs
for member in range(0,ensemble_sz,1):
    meanDirection = displaced_origins[member,3]
    sp.call('mkdir -p ' + experiment_folder + 'angle_' + str(meanDirection) + '/', shell=True)

#Folder where QPE fields are stored
qpe_folder = 'baseline_precip/'

#Loop through period
currentDate = start_date + delta_t
#test_end_date = currentDate + delta_t
while currentDate <= end_date:
	print('Working on ' + currentDate.strftime("%Y%m%d_%H%M"))
	for member in range(0,ensemble_sz,1):
		#Set mean direction
		meanDirection = displaced_origins[member,3]
		#Make a copy of QPE field: precip.20180712_2350.crest.tif
		#sp.call('cp ' + qpe_folder + 'precip.' + currentDate.strftime("%Y%m%d_%H%M") + '.crest.tif ' + experiment_folder + 'angle_' + str(meanDirection) + '/', shell=True)
		# iso_mrms.20180527_1920.tif
		sp.call('cp ' + qpe_folder + 'iso_mrms.' + currentDate.strftime("%Y%m%d_%H%M") + '.tif ' + experiment_folder + 'angle_' + str(meanDirection) + '/precip.' + currentDate.strftime("%Y%m%d_%H%M") + '.crest.tif', shell=True)

    		#Move origin of QPE
		delta_x = origin_lon-displaced_origins[member,1]
		delta_y = origin_lat-displaced_origins[member,0]

		adj_ulx = ulx+delta_x
		adj_lrx = lrx+delta_x
		adj_uly = uly+delta_y
        	adj_lry = lry+delta_y

		#New coordinates to make grid smaller
		xmin = adj_ulx + xres		
		ymin = adj_lry - yres
		xmax = adj_lrx - xres
		ymax = adj_uly + yres

		#Send package to worker
		outputfile = experiment_folder + 'angle_' + str(meanDirection) + '/' + 'precip.' + currentDate.strftime("%Y%m%d_%H%M") + '.crest.tif'
		package = [str(adj_ulx), str(adj_uly), str(adj_lrx), str(adj_lry), outputfile, str(xres), str(yres), str(xmin), str(ymin), str(xmax), str(ymax), experiment_folder + 'angle_' + str(meanDirection) + '/', currentDate.strftime("%Y%m%d_%H%M")]
		qu.put(package)

	#Advance a time step
	currentDate = currentDate + delta_t

#block until all tasks are done
qu.join()

#Notify end of execution (optional)
#mail('myusername@mailservice.com', 'QPE generation DONE', 'Grids are ready.')
