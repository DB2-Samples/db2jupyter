#
# Jupyter notebooks for Db2 using Python 3.x format
# Version 1.0
# 2017-09-21
# Author: George Baklarz
#

FROM continuumio/anaconda3

ENV   DESCRIPTION="Db2 Jupyter Notebook" \
      VERSION="1.0" \
      BUILD_DATE="2017-09-21"
      
EXPOSE 8888

VOLUME /opt/notebooks

#
# Need compiler in this container for the Db2 drivers
#
RUN apt-get update && apt-get install -y gcc \
 && rm -rf /var/lib/apt/lists/*
 
#
# Easy Install will install the Db2 Python driver
#
RUN easy_install ibm-db

#
# Create the directory for jupyter defaults
#
RUN mkdir /root/.jupyter

#
# Generate a null password for the Jupyter notebook connection
#
RUN echo "c.NotebookApp.token = u''" >> ~/.jupyter/jupyter_notebook_config.py

#
# Command to start Jupyter in the container
#
CMD jupyter notebook --NotebookApp.token= --notebook-dir=/opt/notebooks --ip='*' --port=8888 --no-browser --allow-root
