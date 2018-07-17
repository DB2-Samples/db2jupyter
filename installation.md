## Installation Requirements
These files in the Jupyter directory need to be loaded onto your workstation or server where Jupyter notebooks normally run. If you do not have Jupyter installed, there are a number of articles available on the web that tell you how to get it up and running. I've given up a quick write-up below on what you need to do at a minimum to use these notebooks.

### Jupyter
You need to have Jupyter notebook installed on your system, which also needs Python to be installed on your system. If you already have Python available, odds are that you have Jupyter installed as well. The next set of commands will install Python on your platform and then install the Jupyter components.

### Anaconda or Miniconda
Anaconda is an Open Data Science Platform that is powered by Python http://www.continuum.io. The platform keeps track of packages and their dependencies for development with Jupyter notebooks and Python. This makes it very easy to install extensions for Python without having to manually install everything.

Download the Anaconda or Miniconda package applicable to your platform. Miniconda creates the minimal system required for using Python and Jupyter, while Anaconda installs all major packages. There are two versions of Python - V2 or V3. While it doesn't matter which one you use for most notebooks, there are some situations where you may want to use the Python 2 library. For Windows I would recommend using Python 2 in order to use the free Microsoft Compiler for Python. This becomes important when you want to add the ibm_db package to connect to a DB2 server.

After installing Anaconda, you should issue the following commands from a command line shell that will update and install components required by Db2 notebooks.
```
conda update conda      - This will update the Anaconda distribution so you have the latest code
conda install -y -c conda-forge ipywidgets qgrid - Add components needed for displaying result sets 
apt-get update          - Update apt-get catalog
apt-get install -y gcc  - Make sure a C compiler is available for the Db2 driver
easy_install ibm-db     - Install the Db2 Python drivers
```

At this point your installation should have Jupyter available on your system. To start the notebook server you need to issue the following command:
```
jupyter notebook (opens browser)
jupyter notebook --no-browser (runs as a service)
```
The first command will open up a browser window that displays your notebooks. You can click on one of these notebooks to see the contents. If no notebooks are available, you will need to move the files in the Github jupyter directory to a local folder on your system that the program can access.

### Db2 Extensions

To create a connection to Db2 with the Python Db2 extensions you must install the ibm_db package. This package adds appropriate database commands to Python so that it can access the data directly. The ibm_db package is not available as part of the Anaconda/Miniconda package so you need to use a different command to install it.

For the Linux environments, a compiler is already installed that will build the ibm_db extensions. You only need to issue the following command to install the DB2 drivers:
```
easy_install ibm_db
```
On Windows, there is no default compiler. For Python V2, Microsoft makes available a C compiler just for Python usage. To find this compiler, search for "Python 2.7 C Compiler Windows" and then download and install this compiler. Once that is done you may also have to install the Db2 Client drivers. These drivers are part of a Db2 database installation, so you may already have them installed. If not, search for the DB2 Client Drivers and download one appropriate for your platform. These drivers are needed for compiling the code.

Once you've installed the Db2 driver, note its location on disk. The following commands need to be issued to get the driver properly installed.
```
set IBM_DB_HOME=c:\Program Files\IBM\SQLLIB\    -- Location of DB2 installation
cd Program files\ibm\sqllib\dsdriver\python32   -- Move to the directory in your command line
easy_install ibm_db
```
When the command completes you will have access to Db2 from within the Jupyter notebooks.
