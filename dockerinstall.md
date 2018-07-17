## Creating a Docker Container for Db2 and Jupyter Notebooks
You can create a Docker image that will contain Jupyter Notebooks, the Db2 drivers, and all of the examples found in this Github repository.

Assuming that you have Docker running on Windows, Mac, or Linux, the following commands will create a Docker image for you.

1) Download the `db2jupyter.docker` file and place it into a directory of your choice
2) Open up a command window that is able to issue Docker commands (either use Kitematic CLI command line, or a terminal window on Mac or Linux).
3) Navigate to the directory that the `db2jupyter.docker` file is located (i.e. cd or chdir)
4) Issue the following command to create a Docker image:
```Python
docker build -t db2jupyter -f db2jupyter.docker .    <- Note the period at the end
```

5) Once the build is complete (there will be some warning messages with the ibm_db creation) you can now run the docker container with the following command.
```Python
docker run --name db2jupyter -d -p 8888:8888 db2jupyter 
```

6) If  port 8888 is already in use on your system you will have to give it a different port number. For instance, the following command will map the host port 9999 to port 8888 inside the Docker container.
```Python
docker run --name db2jupyter -d -p 9999:8888 db2jupyter 
```

7) Use your favorite browser to navigate to `localhost:8888` and all of the Db2 notebooks will be listed and available for use.
