## How the system currently works - 

(Note: This document needs to be updated whenever some major change is performed)

This is a system wherein a volunteer can contribute his/her computing resources for a CPU-intensive project (like processing some kind of huge data set) and send the results back to the source.<br />

The ultimate goal is to make the life of the volunteer easy by enabling him/her to just execute a file(Let's call it the client_installer from now on.), and do pretty much nothing else, while a docker-container spawned in the volunteer's machine talks to the source, sending results and crunching more data. <br />

The idea is that everything the volunteer needs in terms of software environment is available through the docker-image provided by the source. All the client_installer has to do is to create and run a container from that image.<br />

Currently, this is how the interaction happens.<br />

* Client downloads install_me.sh.(This is the client_installer) and runs it.
  * This file installs following into the client's system (TODO: Should we use ansible for this? Seems more stable than writing home-brewed bash scripts)-
    * docker
    * python
    * pip
    * flask
    * git
  * It downloads the repository from [github](https://github.com/arcolife/dockerComp.git), which contains the client-side helper files - like launch.sh being called from within the script.
  * The launch.sh file creates 4 new containers from the downloaded image. Each of these containers have a flask-nginx server setup. The client_installer file (not the Flask server running inside the container) sends all the container details to the server, which stores these details.(If you have a source-server not running locally, then change the SERVER_HOSTNAME variable in `install_me.sh`)(TODO: Is there a need for client-server?)
  * Now, after the info about the client containers is sent to the server, these containers await the server sending them a request.(TODO: This flow seems flawed. Either this is wrong, or my understanding is wrong.)
  * The rest of the files present in the client_side folder simply represent the server that is running inside the docker container and are not executed in the host machine, but are run within the container.

* The server-side code is being run by the source(the scientist guy/gal who needs the data). It's main goal is to send data to the clients, and then receive responses for the respective requests from different clients. It's basically a Flask server (whose hostname can be specified in the install_me.sh file in the variable `SERVER_HOSTNAME`) and running a Mongodb database.(TODO: Server needs to handle registeration and purging of containers as well)

* When the server needs data from the clients, the `/assign/all` url is called (not automatically, it needs to be explicitly called) which sends the computation details(in the current example, it's a list of tuples, which contain 2 random numbers) to the client in a round-robin fashion.(Note: Currently, the server runs `docker ps -q` to get the details, which is wrong. Have to fix it by accessing the db and then getting the details)

* The server sends the computational details to the client using a curl request in the `scripts/test.sh` file. The client computes it and sends a response which the server currently just prints.(TODO: Store it, along with the client who sent it)
