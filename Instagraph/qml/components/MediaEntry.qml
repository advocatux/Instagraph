import QtQuick 2.4
import Ubuntu.Components 1.3
import QtQuick.LocalStorage 2.0
import QtMultimedia 5.6
import Ubuntu.Components.Popups 1.3
import Ubuntu.Content 1.3
import Ubuntu.DownloadManager 1.2
import QtGraphicalEffects 1.0

import "../js/Storage.js" as Storage
import "../js/Helper.js" as Helper
import "../js/Scripts.js" as Scripts

Column {
    id: entry_column
    spacing: units.gu(1)

    Item {
        width: parent.width
        height: units.gu(0.1)
    }

    Row {
        x: units.gu(1)
        width: parent.width - units.gu(2)
        spacing: units.gu(1)
        anchors {
            horizontalCenter: parent.horizontalCenter
        }

        CircleImage {
            id: feed_user_profile_image
            width: units.gu(5)
            height: width
            source: typeof user != 'undefined' && typeof user.profile_pic_url != 'undefined' ? user.profile_pic_url : "../images/not_found_user.jpg"

            MouseArea {
                anchors {
                    fill: parent
                }
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("../ui/OtherUserPage.qml"), {usernameId: user.pk});
                }
            }
        }

        Column {
            spacing: units.gu(0.2)
            width: parent.width - units.gu(9)
            anchors {
                verticalCenter: parent.verticalCenter
            }

            Label {
                text: typeof user != 'undefined' && typeof user.username != 'undefined' ? user.username : ''
                font.weight: Font.DemiBold
                wrapMode: Text.WordWrap

                MouseArea {
                    anchors {
                        fill: parent
                    }
                    onClicked: {
                        pageStack.push(Qt.resolvedUrl("../ui/OtherUserPage.qml"), {usernameId: user.pk});
                    }
                }
            }

            Label {
                text: typeof location != 'undefined' && typeof location.name != 'undefined' ? location.name : ''
                fontSize: "medium"
                font.weight: Font.Light
                wrapMode: Text.WordWrap
            }
        }

        Icon {
            anchors {
                verticalCenter: parent.verticalCenter
            }
            width: units.gu(2)
            height: width
            name: "down"

            MouseArea {
                anchors {
                    fill: parent
                }
                onClicked: {
                    if (my_usernameId == user.pk || photo_of_you || (!user.is_private && code)) {
                        PopupUtils.open(popoverComponent)
                    }
                }
            }
        }
    }

    Component {
        id: singleMedia

        Item {
            FeedImage {
                id: feed_image
                width: parent.width
                height:parent.width/bestImage.width*bestImage.height
                source: bestImage.url
            }

            Icon {
                id: is_video_icon
                width: units.gu(3)
                height: width
                anchors {
                    right: parent.right
                    rightMargin: units.gu(2)
                    top: parent.top
                    topMargin: units.gu(2)
                }
                visible: false
                name: "camcorder"
                color: "#ffffff"
            }
            DropShadow {
                anchors.fill: is_video_icon
                source: is_video_icon
                horizontalOffset: 2
                verticalOffset: 2
                radius: 8.0
                samples: 15
                color: "#80000000"
                visible: media_type === 2
            }

            MediaPlayer {
                id: player
                source: video_url
                autoLoad: false
                autoPlay: false
                loops: MediaPlayer.Infinite
            }
            VideoOutput {
                id: videoOutput
                source: player
                fillMode: VideoOutput.PreserveAspectCrop
                width: 800
                height: 600
                anchors.fill: parent
                visible: media_type == 2
            }

            MouseArea {
                anchors {
                    fill: parent
                }
                onClicked: {
                    if (media_type === 2) {
                        console.log('PLAY VIDEO')
                        console.log(video_url)
                        if (player.playbackState == MediaPlayer.PlayingState) {
                            player.stop()
                        } else {
                            player.play()
                        }
                    }
                }
                onDoubleClicked: {
                    last_like_id = id;
                    instagram.like(id);
                }
            }

            Connections {
                target: instagram
                onLikeDataReady: {
                    if (JSON.parse(answer).status === "ok" && last_like_id === id) {
                        imagelikeicon.color = UbuntuColors.red;
                        imagelikeicon.name = "like";
                    }
                }
                onUnLikeDataReady: {
                    if (JSON.parse(answer).status === "ok" && last_like_id === id) {
                        imagelikeicon.color = "";
                        imagelikeicon.name = "unlike";
                    }
                }
            }
        }
    }

    Component {
        id: carouselMedia

        Item {
            CarouselSlider {
                id: carouselSlider
                width: parent.width
                height: parent.height - units.gu(2)
                model: carousel_media_obj
            }

            Row {
                id: slideIndicator
                height: units.gu(2)
                spacing: units.gu(0.5)
                anchors {
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                }

                Repeater {
                    model: carousel_media_obj.count
                    delegate: Rectangle {
                        height: units.gu(0.7)
                        width: units.gu(0.7)
                        radius: width/2
                        antialiasing: true
                        anchors.verticalCenter: parent.verticalCenter
                        color: carouselSlider.currentIndex == index ? UbuntuColors.blue : "black"
                        Behavior on color {
                            ColorAnimation {
                                duration: UbuntuAnimation.FastDuration
                            }
                        }
                    }
                }
            }
        }
    }

    Loader {
        property var bestImage: typeof carousel_media_obj !== 'undefined' && carousel_media_obj.count > 0 ?
                                    Helper.getBestImage(carousel_media_obj.get(0).image_versions2.candidates, parent.width) :
                                    media_type == 1 || media_type == 2 ?
                                        Helper.getBestImage(images_obj.candidates, parent.width) :
                                        {"width":0, "height":0, "url":""}


        width: parent.width
        height: typeof carousel_media_obj !== 'undefined' && carousel_media_obj.count > 0 ?
                    ((parent.width/bestImage.width*bestImage.height) + units.gu(2)) :
                    media_type == 1 || media_type == 2 ?
                        parent.width/bestImage.width*bestImage.height :
                        0

        sourceComponent: typeof carousel_media_obj !== 'undefined' && carousel_media_obj.count > 0 ?
                             carouselMedia :
                             media_type == 1 || media_type == 2 ?
                                 singleMedia :
                                 singleMedia
    }

    Row {
        x: units.gu(1)
        width: parent.width - units.gu(2)
        spacing: units.gu(2.3)
        anchors.horizontalCenter: parent.horizontalCenter

        Item {
            width: units.gu(4)
            height: width

            Icon {
                id: imagelikeicon
                anchors.verticalCenter: parent.verticalCenter
                width: units.gu(3)
                height: width
                name: has_liked === true ? "like" : "unlike"
                color: has_liked === true ? UbuntuColors.red : "#000000"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (imagelikeicon.name === "unlike") {
                        last_like_id = id;
                        instagram.like(id);
                    } else if (imagelikeicon.name === "like") {
                        last_like_id = id;
                        instagram.unLike(id);
                    }
                }
            }
        }

        Item {
            width: units.gu(4)
            height: width

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                width: units.gu(3)
                height: width
                name: "message"
                color: "#000000"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("../ui/CommentsPage.qml"), {photoId: id, mediaUserId: user.pk});
                }
            }
        }

        Item {
            width: units.gu(4)
            height: width

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                width: units.gu(3)
                height: width
                name: "share"
                color: "#000000"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("../ui/ShareMediaPage.qml"), {mediaId: id, mediaUser: user});
                }
            }
        }

        Item {
            width: units.gu(4)
            height: width

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                width: units.gu(3)
                height: width
                name: "save"
                color: "#000000"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    var singleDownload = downloadComponent.createObject(mainView)
                    singleDownload.contentType = ContentType.Pictures
                    singleDownload.download(image_versions2.candidates[0].url)
                }
            }
        }
    }

    Flow {
        x: units.gu(1)
        width: parent.width - units.gu(2)
        visible: typeof like_count !== 'undefined' && like_count !== 0 ? true : false
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: units.gu(1)

        Icon {
            width: units.gu(2)
            height: width
            name: "like"

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("../ui/MediaLikersPage.qml"), {photoId: id});
                }
            }
        }

        Label {
            text: like_count + i18n.tr(" likes")
            font.weight: Font.DemiBold
            wrapMode: Text.WordWrap

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("../ui/MediaLikersPage.qml"), {photoId: id});
                }
            }
        }
    }

    Column {
        x: units.gu(1)
        width: parent.width - units.gu(2)
        spacing: units.gu(0.5)

        Text {
            visible: typeof caption !== 'undefined' && caption !== null ?
                         (typeof caption.text !== 'undefined' ? true : false) :
                         false
            text: typeof caption !== 'undefined' && caption !== null ?
                      (typeof caption.text !== 'undefined' ? Helper.formatUser(caption.user.username) + ' ' + Helper.formatString(caption.text) : "") :
                      ""
            wrapMode: Text.WordWrap
            width: parent.width
            textFormat: Text.RichText
            onLinkActivated: {
                Scripts.linkClick(link)
            }
        }

        Label {
            visible: has_more_comments === true ? true : false
            text: i18n.tr("View all %1 comments").arg(comment_count)
            color: UbuntuColors.darkGrey
            wrapMode: Text.WordWrap
            width: parent.width

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("../ui/CommentsPage.qml"), {photoId: id});
                }
            }
        }

        Repeater {
            model: preview_comments

            Text {
                width: parent.width
                text: Helper.formatUser(user.username) + ' ' + Helper.formatString(ctext)
                wrapMode: Text.WordWrap
                textFormat: Text.RichText
                onLinkActivated: {
                    Scripts.linkClick(link)
                }
            }
        }

        Column {
            width: parent.width
            spacing: units.gu(1)

            Label {
                text: Helper.milisecondsToString(taken_at)
                fontSize: "small"
                color: UbuntuColors.darkGrey
                font.weight: Font.Light
                wrapMode: Text.WordWrap
                font.capitalization: Font.AllLowercase
            }
        }
    }
}
