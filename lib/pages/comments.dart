import 'package:flutter/material.dart';
import 'package:srmconnect/widgets/header.dart';

class Comments extends StatefulWidget {

  final String postId;
  final String postOwnerId;
  final String postMediaUrl;

  Comments({
    this.postId,
    this.postOwnerId,
    this.postMediaUrl,
  });


  @override
  CommentsState createState() => CommentsState(
    postId: this.postId,
    postOwnerId: this.postOwnerId,
    postMediaUrl: this.postMediaUrl,
  );
}

class CommentsState extends State<Comments> {

  TextEditingController commentController = TextEditingController();
  final String postId;
  final String postOwnerId;
  final String postMediaUrl;

  CommentsState({
    this.postId,
    this.postOwnerId,
    this.postMediaUrl,
  });

  buildComments(){
    return Text("Comment");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: "Comments"),
      body: Column(
        children: <Widget>[
          Expanded(child: buildComments()),
          Divider(),
          SafeArea(
            child: ListTile(
              title: TextFormField(
                controller: commentController,
                decoration: InputDecoration(
                  labelText: "Write a comment...",
//                  hintText: "Say something nice",
                ),
              ),
              trailing: OutlineButton(
                highlightElevation: 2.0,
                onPressed: () => print("add comment"),
                borderSide: BorderSide.none,
                child: Text('POST'),
              ),
            ),
          ),
          SizedBox(height: 5.0,)
        ],
      ),
    );
  }
}

class Comment extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('Comment');
  }
}
