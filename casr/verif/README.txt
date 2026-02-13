This file will guide you on how to run the tests for yourself.

All tests are done under Ubuntu 24.04 LTS enviroment.

All tests are done in parallel mode.

Important : the following steps are to be run at the root of verif folder ( next to this file )

step 1:
    run in order

    $ sudo apt update -y
    $ sudo apt install -y python3 python3-pip python3-venv ghdl make

step 2:
    check all the above packages

    $ python3 --version                  // should show 3.x.x
    $ pip --version                      // should show 24.x.x
    $ python3 -m venv --help             // should show help message
    $ ghdl --version                     // should show ghdl version
    $ make --version                     // should show make version

    if any of the above fails repeat step 1 with individual packages: 
        $ sudo apt install -y {package_name}
    and check again

step 3:
    create a virtual environment to run the tests in isolation

    $ python3 -m venv venv               // this will create a folder named venv
    $ ls                                 // should show venv folder
    $ source venv/bin/activate           // this will activate the virtual environment

    to check if the virtual environment is activated:
        you will see a (venv) appear before the prompt.
        Example:
            (venv) $ which python           // should show path to python in venv

step 4:
    install cocotb inside the virtual environment
    
    (venv) $ pip install cocotb

    check installation:
        (venv) $ cocotb-config --version           // should show cocotb version

the enviroment should be set now to run the tests.

now you need to navigate to the test folder while the virtual environment is activated and run the tests.
Example:
    (venv) $ cd casr30/casr30_test2
    (venv) $ make

there are output.log files at the root of each test for reference.
