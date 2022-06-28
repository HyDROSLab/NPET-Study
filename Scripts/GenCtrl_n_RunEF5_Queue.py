#!/usr/bin/env python
# -*- coding: utf-8 -*-
import Queue as qu
from threading import Thread
import os
import subprocess as sp
import datetime as dt
import glob
import numpy as np

# Function to send error emails
def mail(to, subject, text):
        sp.call('echo "' + text + '" | mail -s "' + subject + '" ' + to, shell=True)

def worker():
        while True:
                #Obtain string array of filenames and folders 
                package = qu.get()                
		
		#Prepare arguments
		textFile = package[0]
		meanAngle = package[1]
		dispL = package[2]
		pathR = package[3]

		# Edit control file
		with open(textFile, 'r') as file:
        		filedata = file.read()

		#Replace wildcard labels in control file
		
		filedata = filedata.replace('{DISPLACEMENT}', dispL)
		filedata = filedata.replace('{ANGLE}', meanAngle)
		filedata = filedata.replace('{ROOTPATH}', pathR)

    		with open(textFile, 'w') as file:
        		file.write(filedata)
        	file.close()

		# Run EF5
		print("/hydros/humberva/EF5/EF5/bin/ef5 " + textFile)
            	sp.call("/hydros/humberva/EF5/EF5/bin/ef5 " + textFile, shell=True)

                #Complete worker's task
                qu.task_done()

# Identify current working directory path
current_path = os.getcwd()
# Split into subfolders
subfolders = current_path.split("/")
n_levels = len(subfolders)
# Make the root path
root_path = "/".join(subfolders[0:n_levels-1])

#Type of perturbation: steady_state or dynamic
disp_length = 100

# INSTRUCTIONS: For sensitivity analysis run, using perturbed QPEs displaced in 120 directions, look for and uncomment lines under "# Sensitivity Analysis Run: 120 directions". For running simulations using QPEs shifted using C2020 method, look for and uncomment lines under "# C2020 Run".

#Read in new origins to create synthetic fields
#latitude,longitude,distance(km),direction angle(degrees)
# Sensitivity Analysis Run: 120 directions
#perturbation_file =  '../QPEperturbations/disp' + str(disp_length) + 'km/origin_round_form_distance_enforced_' + str(disp_length) + 'km.csv'
# C2020 Run
perturbation_file = '../QPEperturbations/c2020_method_disp' + str(disp_length) + 'km/c2020_45deg_distance_enforced_' + str(disp_length) + 'km.csv'
displaced_origins = np.loadtxt(perturbation_file, dtype='float', delimiter=',', skiprows=1)

ensemble_sz = np.shape(displaced_origins)[0]

#Initiate Queue and Workers
qu = qu.Queue()
numworkers = 8
for i in range(numworkers):
        t = Thread(target=worker)
        t.daemon = True
        t.start()

# Root folder
# C2020 Run
experiment_folder = '../EF5/Outputs/c2020_method_disp' + str(disp_length) + 'km/'
# Sensitivity Analysis Run: 120 directions
#experiment_folder = '../EF5/Outputs/disp' + str(disp_length) + 'km/'

# EF5 control template
ef5_template = '../EF5/Ellicot_ef5_ctrl_template.txt'

#Create folders to store synthetic QPEs
for member in range(0,ensemble_sz,1):
    # Create folder for this run
    meanDirection = displaced_origins[member,3]
    # Clean up existing Directory
    sp.call('rm -fr ' + experiment_folder + 'angle_' + str(meanDirection) + '/', shell=True)
    # Create folder
    sp.call('mkdir -p ' + experiment_folder + 'angle_' + str(meanDirection) + '/', shell=True)


    # Copy control template
    ctr_file = experiment_folder + 'angle_' + str(meanDirection) + '/ef5_ctrl.txt'
    sp.call('cp ' + ef5_template + ' ' + ctr_file, shell=True)

    #Pass string array of filenames and folders
    # Sensitivity Analysis Run: 120 directions
    #qu.put([ctr_file, 'angle_' + str(meanDirection), 'disp' + str(disp_length) + 'km', root_path])
    # C2020 Run
    qu.put([ctr_file, 'angle_' + str(meanDirection), 'c2020_method_disp' + str(disp_length) + 'km', root_path])

#block until all tasks are done
qu.join()

#Notify end of execution
#mail('myusername@mailservice.com', 'EF5 simulation DONE', 'Grids are ready.')
