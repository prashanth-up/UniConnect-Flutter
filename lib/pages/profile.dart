import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
//import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:srmconnect/models/user.dart';
import 'package:srmconnect/pages/edit_profile.dart';
import 'package:srmconnect/pages/home.dart';
import 'package:srmconnect/widgets/header.dart';
import 'package:srmconnect/widgets/post_tile.dart';
import 'package:srmconnect/widgets/progress.dart';
import 'package:srmconnect/widgets/post.dart';

class Profile extends StatefulWidget {

  final String profileId;

  Profile({this.profileId});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {

  bool isFollowing = false;

  final String currentUserId = currentUser?.id;
  String postOrientation = "grid";
  bool isLoading = false;
  int postCount = 0;
  int followerCount = 0;
  int followingCount = 0;

  List<Post> posts = [];


  @override
  void initState() {
    super.initState();
    getProfilePosts();
    getFollowers();
    getFollowing();
    checkIfFollowing();
  }

  checkIfFollowing() async{
    DocumentSnapshot doc = await followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUserId)
        .get();
    setState(() {
      isFollowing = doc.exists;
    });
  }


  getFollowers() async {
    QuerySnapshot snapshot = await followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .getDocuments();
    setState(() {
      followerCount = snapshot.documents.length;
    });
  }

  getFollowing() async{
    QuerySnapshot snapshot = await followingRef
      .document(widget.profileId)
      .collection('userFollowing')
      .getDocuments();
    setState(() {
      followingCount = snapshot.documents.length;
    });
  }

  getProfilePosts() async{
    setState(() {
      isLoading = true;
    });
    QuerySnapshot snapshot = await postsRef
        .document(widget.profileId)
        .collection('userPosts')
        .orderBy('timestamp', descending: true)
        .getDocuments();
    setState(() {
      isLoading = false;
      postCount = snapshot.documents.length;
      posts = snapshot.documents.map((doc) => Post.fromDocument(doc))
      .toList();
    });
  }

  buildCountColumn(String label, int count){
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 22.0, fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 4.0),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 15.0,
              fontWeight: FontWeight.w400,
            ),
          ),
        )
      ],
    );
  }

  editProfile(){
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => EditProfile(
        currentUserId : currentUserId)
    ));
  }

  Container buildButton({String text, Function function}){
    return Container(
      padding: EdgeInsets.only(top: 1.0),
      child: FlatButton(
        onPressed: function,
        child: Container(
          width: 210.0,
          height: 27.0,
          child: Text(text,
            style: TextStyle(
              color: isFollowing ? Colors.black :Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isFollowing ? Colors.white :Colors.blue,
            border: Border.all(
              color: isFollowing ? Colors.grey : Colors.blue,
            ),
            borderRadius: BorderRadius.circular(5.0),
          ),
        ),
      ),
    );
  }

  buildProfileButton(){
    //Own profile then - edit User
    bool isProfileOwner = currentUserId == widget.profileId;

    if(isProfileOwner){
      return buildButton(
        text : "Edit Profile",
        function: editProfile
      );
    }else if(isFollowing){
      return buildButton(text: "Unfollow", function: handleUnfollowUser);
    }
    else if(!isFollowing){
      return buildButton(
        text: "Follow",
        function: handleFollowUser,
      );
    }

  }


  handleUnfollowUser(){
    setState(() {
      isFollowing = false;
    });
    // remove follower
    followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUserId)
        .get().then((doc){
          if(doc.exists){
            doc.reference.delete();
          }
        });
    // remove followgn
    followingRef
        .document(currentUserId)
        .collection('userFollowing')
        .document(widget.profileId)
        .get().then((doc){
          if(doc.exists){
            doc.reference.delete();
        }
    });

    // add activity feed item to notifiy that user
    activityFeedRef
        .document(widget.profileId)
        .collection('feedItems')
        .document(currentUserId)
        .get().then((doc){
          if(doc.exists){
            doc.reference.delete();
          }
        });
  }

  handleFollowUser(){
    setState(() {
      isFollowing = true;
    });
    // Make auth user follower of other user and update their collection
    followersRef
      .document(widget.profileId)
      .collection('userFollowers')
      .document(currentUserId)
      .setData({});
    // Put that user on your collction
    followingRef
      .document(currentUserId)
      .collection('userFollowing')
      .document(widget.profileId)
      .setData({});

    // add activity feed item to notifiy that user
    activityFeedRef
      .document(widget.profileId)
      .collection('feedItems')
      .document(currentUserId)
      .setData({
        "type" :  "follow",
        "ownerId" : widget.profileId,
        "username" : currentUser.username,
        "userId" : currentUserId,
        "userProfileImg" : currentUser.photoUrl,
        "timestamp" : timestamp,
      });
  }


  buildProfileHeader(){
    return FutureBuilder(
      future: usersRef.document(widget.profileId).get(),
      builder: (context,snapshot){
        if(!snapshot.hasData){
          return circularProgress();
        }
        User user = User.fromDocument(snapshot.data);
        return Padding(
          padding: EdgeInsets.all(14.0),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 40.0,
                    backgroundColor: Colors.grey,
                    backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            buildCountColumn("Posts",postCount),
                            buildCountColumn("Followers",followerCount),
                            buildCountColumn("Following",followingCount),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            buildProfileButton(),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 16.0),
                child: Text(
                  user.username,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 4.0),
                child: Text(
                  user.displayName,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 2.0),
                child: Text(
                  user.bio,
                ),
              )
            ],
          ),
        );
      },
    );
  }

  buildProfilePosts(){
    if(isLoading){
      return circularProgress();
    }
    else if(posts.isEmpty){
      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SvgPicture.asset('assets/images/no_content.svg',height: 260.0,),
            Padding(
              padding: EdgeInsets.only(top: 20.0),
              child:
                  Text(
                    "No Posts",
                    style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 40.0,
                      fontWeight: FontWeight.bold
                ),
                ),
            ),
          ],
        ),
      );
    }
    else if(postOrientation == "grid"){
      List<GridTile> gridTiles = [];
      posts.forEach((post){
        gridTiles.add(GridTile(child: PostTile(post),));
      });
      return GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: gridTiles,
      );
    }
    else if(postOrientation == "list"){
      return Column(
        children: posts,
      );
    }
  }

  setPostOrientation(String postOrientation){
    setState(() {
      this.postOrientation = postOrientation;
    });
  }

  buildTogglePostOrientation(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          onPressed: () => setPostOrientation("grid"),
          icon: Icon(Icons.grid_on),
          color: postOrientation == "grid" ? Theme.of(context).primaryColor : Colors.grey,
        ),
        IconButton(
          onPressed: () => setPostOrientation("list"),
          icon: Icon(Icons.list),
            color: postOrientation == "list" ? Theme.of(context).primaryColor : Colors.grey,
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: "Profile"),
      body : ListView(
        children: <Widget>[
          buildProfileHeader(),
          Divider(),
          buildTogglePostOrientation(),
          Divider(
            height: 0.0,
          ),
          buildProfilePosts(),
        ],
      ),
    );
  }
}
