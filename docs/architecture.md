## Architecture

The system involves three components:
* **The Server**
* **The Client**
* **The Channel**

### The Server(Seeker)
* It will wait for conections to be made by different clients(simple socket
stuff/ may be something different)
* Once connection is made, it will update it's db
* As needed server will assign, tasks with required configuration to a client
dependending on some criteria (like processing power and stuff)
* This **tasks** will have information like the docker image to be pulled at
the client's side and also could have information related to the task
(perhaps the dataset, not sure though)
* Also, connects to the **channel** to fetch the results.
* The **results** is important, a **result** should/will have a specified
structure, which says the following:
  * The client which has sent the result
  * The time when the result was sent to the **channel**
  * The associated **task id**, there could be multiple
  results for a single task id(See below, **Why ?** section)
  * need to think more...
* It tries to submit the task to the best available client, if the client is
disconnected it tries the next best.

### The Client(Giver)
* This is host where the docker containers having the business logic run
* It receives **tasks** from **the server**, need to think how
(perhaps through the channel, may not be a good idea see **Musings**)
* It will post **the results** to the channel
* The client will also run a flask server, and will send the server
it's own information, thus making a connection to it(perhaps connection
could be made to the channel, see **Musings**)

### The Channel
* This will be the interface between the server and all its clients
* Currently, it will only store the results from all the clients
* And will respond to the calls made by the server for results
* the server will call for results associated with a task id(there could be
multiple results for a task id),
and the channel will return the results based on the task id(a simple lookup).
* The Channel helps in decoupling the client-server communication for collecting
the results

The above three are the components and will add more details as the architecture
is ironed out.

#### Purging of client information from the server
* The Server needs to purge the client information once it is disconnected.
* The server tries to submit a task to a client or gather resource information
from the client, if it couldn't connect to it, it increments a counter, once the
counter reaches a certain count(say 3) the information of that client is
removed from the server's db


Below are some other sections, one is a **Why ?** section that answers some questions,
and the other is a **Musings** section that holds some random thougts on the architecture.

#### Why ?
* Why a single task id has multiple result objects associated to it ?
```
The server could submit a single tasks to multiple clients just for backup,
if one client stops everything then it the server has another client running
the same task. Sometimes, every client can return their own result and these
results may not match with each other, in such cases the server needs to
choose any one result(dependending on some heuristics)
```

#### Musings
* Should the channel be used to keep the tasks as well and clients pick up
the tasks from the channel, but in this way server cannot keep the authority
of assigning the same task to multiple clients.
* How will **The channel** look like, should it be physically separate from
The Server, or should it be co-located with just a logical barrier ? Perhaps,
it makes more sense to keep it logically separate and not physically but
provisions should be made for that too, code should not limit physical separation
* The Channel could be a simple db(no sql) which stores the results as documents
and could be queried based on the task id via a REST Interface, mongo could be used.
* The names should/must be changed, server and client do not do justice to the duties
assigned to them respectively, perhaps the server could me called the seeker
and the client could be called the helper(just a thought)
* The client should register to the The Channel and The Server periodically polls the
channel for newer clients, if there is a delta between last and current call, the server
enters the data in its db(what will this db be ? Should not be the channel, as it plays
a cometely different role)
* From above point, the server stores the info in its db, so that it can directly call
the client for submitting tasks.
