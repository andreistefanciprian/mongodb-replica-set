## Define variables
PROJECT=cedar-card-200213

## Initiate replica set on only one node
rs.initiate( {
   _id : "rs0",
   members: [
      { _id: 0, host: "mongodb0.example.net:27017" },
      { _id: 1, host: "mongodb1.example.net:27017" },
      { _id: 2, host: "mongodb2.example.net:27017" }
   ]
})

## Verify replicaset config on all nodes
rs.conf()
rs.status()

## Create db,collections and docs and verify replica set works
use mydb
db.createCollection("inventory")
db.inventory.insert({ item: "journal", qty: 25, status: "A", size: { h: 14, w: 21, uom: "cm" }, tags: [ "blank", "red" ] })
db.inventory.insert({ item: "notebook", qty: 50, status: "A", size: { h: 8.5, w: 11, uom: "in" }, tags: [ "red", "blank" ] })
db.inventory.insert({ item: "paper", qty: 100, status: "D", size: { h: 8.5, w: 11, uom: "in" }, tags: [ "red", "blank", "plain" ] })
db.inventory.insert({ item: "planner", qty: 75, status: "D", size: { h: 22.85, w: 30, uom: "cm" }, tags: [ "blank", "red" ] })
db.inventory.insert({ item: "postcard", qty: 45, status: "A", size: { h: 10, w: 15.25, uom: "cm" }, tags: [ "blue" ] })
db.inventory.insert({ item: "postcard2", qty: 145, status: "C", size: { h: 10, w: 15.25, uom: "cm" }, tags: [ "blue" ] })

## Issue command on SECONDARY members to alow read ops
db.getMongo().setSlaveOk()

## Verify documents were replicated on Secondary nodes
db.inventory.find().limit(1).pretty()
db.inventory.find( { status: "D" } )
db.inventory.find( {} )
db.inventory.find( { size: { h: 14, w: 21, uom: "cm" } } )
db.inventory.find( { "size.uom": "in" } )
db.inventory.find( { tags: ["red", "blank"] } )

## Force Secondary to become Primary
# In a mongo shell connected to the primary, use the following sequence of operations to make one of the Secondary nodes the primary:
cfg = rs.conf()
cfg.members[0].priority = 0.5
cfg.members[1].priority = 0.5
cfg.members[2].priority = 1
rs.reconfig(cfg)

## Debug commands
gcloud beta compute --project=$PROJECT instances list | grep mongo
telnet mongodb1.example.net 27017
nc -zv mongodb1.example.net 27017
sudo cat /etc/mongod.conf | grep -E "dbpath|replSet|bind_ip"
sudo cat /etc/hosts | grep mongodb
sudo netstat -tapnl | grep mongo
sudo service mongod restart




