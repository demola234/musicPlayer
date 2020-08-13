import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:musicPlayer/components/customButton.dart';
import 'package:musicPlayer/models/config.dart';
import 'package:musicPlayer/models/playListDB.dart';
import 'package:musicPlayer/models/songController.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class CreatePlayList extends StatefulWidget {
  CreatePlayList({this.height, this.width, this.isCreateNew = true});

  final double width;
  final double height;
  final bool isCreateNew;

  @override
  _CreatePlayListState createState() => _CreatePlayListState();
}

class _CreatePlayListState extends State<CreatePlayList> {
  bool createNew;
  String playlistName;
  IconData playlistIcon;
  @override
  void initState() {
    createNew = widget.isCreateNew;
    playlistIcon = Icons.star_border;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Orientation orientation = MediaQuery.of(context).orientation;
    Size viewsSize = MediaQuery.of(context).size;
    TextStyle textStyle = TextStyle(
        fontSize: Config.textSize(context, 4),
        fontWeight: FontWeight.w400,
        fontFamily: 'Acme');

    return Container(
      height: orientation == Orientation.portrait
          ? viewsSize.height
          : viewsSize.width,
      width: orientation == Orientation.portrait
          ? viewsSize.width
          : viewsSize.height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Material(
            elevation: 6.0,
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              height: Config.yMargin(context, widget.height),
              width: Config.yMargin(context, widget.height),
              padding: EdgeInsets.all(20),
              child: Consumer<PlayListDB>(
                builder: (context, playlistDB, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      createNew
                          ? Text(
                              'New playlist',
                              style: textStyle,
                            )
                          : Text(
                              'Add to playlist',
                              style: textStyle,
                            ),
                      createNew
                          ? Expanded(
                              child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextField(
                                      keyboardType: TextInputType.name,
                                      decoration: InputDecoration(
                                        labelText: 'Name',
                                        labelStyle: textStyle,
                                      ),
                                      onChanged: (String newValue) {
                                        setState(() {
                                          playlistName = newValue;
                                        });
                                      },
                                    ),
                                  ]),
                            )
                          : Expanded(
                              child: ListView.builder(
                                itemCount: playlistDB.playList.length,
                                itemBuilder: (context, index) {
                                  return FlatButton(
                                    onPressed: () async {
                                      await playlistDB.addToPlaylist(
                                          playlistDB.playList[index]['name'],
                                          Provider.of<SongController>(context,
                                                  listen: false)
                                              .nowPlaying);
                                          Navigator.pop(context);
                                    },
                                    child: index > 0 &&
                                            index < playlistDB.playList.length
                                        ? Text(
                                            playlistDB.playList[index]['name'],
                                            style: textStyle,
                                          )
                                        : SizedBox.shrink(),
                                  );
                                },
                              ),
                            ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FlatButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Cancel',
                              style: textStyle,
                            ),
                          ),
                          createNew
                              ? FlatButton(
                                  onPressed: () {
                                    Provider.of<PlayListDB>(context,
                                            listen: false)
                                        .createPlaylist(playlistName);
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    'Create playlist',
                                    style: textStyle,
                                  ),
                                )
                              : FlatButton(
                                  onPressed: () {
                                    setState(() {
                                      createNew = true;
                                    });
                                    print(createNew);
                                  },
                                  child: Text(
                                    'New playlist',
                                    style: textStyle,
                                  ),
                                ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
