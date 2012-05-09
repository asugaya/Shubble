# Echo server program
import socket
import threading
import datetime
import gdata.docs.client
import gdata.sample_util
import gdata.docs.service
import gdata.acl.data 
import gdata.docs.data
import time
HOST = 'codebanana.com'                 # Symbolic name meaning the local host
PORT = 50002              # Arbitrary non-privileged port
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.bind((HOST, PORT))

#This is our current group
currentGroupURL = ""
groupStartTime = None
groupNum = 0

#This is how long we wait between groups (any users that appear within this time of the first connection is in the same group)
GROUP_WAIT_TIME=5 #in seconds
SAME_GROUP_WAVE_TIME_THRESHOLD = 10
#This is stuff we need for creating the google doc
source = 'Shubble'
client = gdata.docs.client.DocsClient(source=source)
gdata.sample_util.authorize_client(
        client,
        service=client.auth_service,
        source=client.source,
        scopes=client.auth_scopes
    )

#Keep track of the different times.
groups = [] #groups looks like [{"t":50, "url":"https://blahblah"}]
#Always listen to sockets
while True:
	s.listen(1)
	conn, addr = s.accept()
	print 'Connected by', addr
	data = conn.recv(1024)
	try:
		waveTime = int(data)
	except ValueError:
		print "Not an int! " + data
		waveTime = -999999999
	existingGroup = None
	for g in groups:
		if abs(g["t"] - waveTime) < SAME_GROUP_WAVE_TIME_THRESHOLD:
			existingGroup = g
			break;
	print waveTime
	print groups
	#If it's been a while, create a current group
	if existingGroup == None:
		title = "Awesome Shubble Document " + str(datetime.datetime.now().isoformat(' '))
		title = str(datetime.datetime.now().isoformat(' '))
		#entry = gd_client.Upload(ms, title)
		doc = gdata.docs.data.Resource(type='document', title=title)
		doc.description = gdata.docs.data.Description('This is a shared text document created through Shubble')
		path = "/home/asugaya/scripts/pyScripts/blankDoc.txt"
		media = gdata.data.MediaSource()
		media.SetFileHandle(path, 'text/plain')
		doc = client.CreateResource(doc, media=media)
		scope = gdata.acl.data.AclScope(type='default') 
		role = gdata.acl.data.AclRole(value='writer') 
		acl_entry = gdata.docs.data.AclEntry(scope=scope, role=role) 

		new_acl = client.AddAclEntry(doc,acl_entry)#gd_client.Post(acl_entry, entry.GetAclFeedLink().href) 		
		groupStartTime = datetime.datetime.now()
		groupNum += 1
		currentGroupURL = doc.GetAlternateLink().href
		currentGroupURL = currentGroupURL.replace("edit", "mobilebasic")
		#currentGroupURL = "testGroup"+str(groupNum) #TODO: create a google doc and set the URL here
		existingGroup = {"t":waveTime,"url":currentGroupURL}
		groups.append(existingGroup)
		t = threading.Timer(GROUP_WAIT_TIME, lambda: groups.pop(0))
		t.start()
	time.sleep(1)
	conn.send(existingGroup["url"]+"\r\n")
	conn.close()
