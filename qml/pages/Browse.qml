import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.3
import "../components/js/Utils.js" as Utils
import "../components/js/Storage.js" as DB
import "../components/js/Favorites.js" as FavoritesUtils


Page {
    id: page
    property var listType: Utils.Favorites

    SilicaListView {
        id: stationListView
        VerticalScrollDecorator { flickable: issuesPageListView }
        anchors.fill: parent

        PullDownMenu {
                    id: pulleyMeny
                    MenuItem {
                        text: qsTr("Top 100")
                        visible: listType !== Utils.Top100
                        onClicked: {
                            pageStack.replace(Qt.resolvedUrl("Browse.qml"), {listType: Utils.Top100});
                        }
                    }
                    MenuItem {
                        text: qsTr("Search")
                        visible: listType !== Utils.Search
                        onClicked: {
                            pageStack.replace(Qt.resolvedUrl("Browse.qml"), {listType: Utils.Search});
                        }
                    }
                }


        header: Column {
                    PageHeader {
                        title: qsTr(listType.header)
                        width: page.width
                    }

                    SearchField {
                        id: searchInput
                        width: page.width
                        visible: listType === Utils.Search

                        EnterKey.enabled: text.length > 0
                        EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                        EnterKey.onClicked: {
                            if(text != "") {
                                python.search(text)
                            }
                            else {
                                focus = false;
                            }
                        }
                    }
                }

        model: ListModel {
            id: stationModel
        }

        delegate: ListItem {
            id: listItem
            menu: itemContextMenu
            width: parent.width
            contentHeight: Theme.itemSizeLarge

            Row {
                id: quickControlsItem
                anchors.fill: parent
                spacing: Theme.paddingLarge

                Image {
                    id: stationIcon
                    source: pictureBaseURL + picture1Name

                    smooth: true
                    fillMode: Image.PreserveAspectFit
                    cache: true

                    sourceSize.height: parent.height - 20
                }

                Column {
                    id: trackInfo
                    width: parent.width - stationIcon.width - Theme.paddingLarge
                    height: parent.height
                    spacing: -Theme.paddingSmall

                    Label {
                        id: stationName
                        text: name
                    }

                    Label {
                        width: parent.width
                        font.pixelSize: Theme.fontSizeExtraSmall
                        truncationMode: TruncationMode.Fade
                        color: Theme.secondaryColor
                        text: "From " + country + ": " + genresAndTopics.split(",")[0]
                    }

                    Label {
                        width: parent.width
                        font.pixelSize: Theme.fontSizeSmall
                        truncationMode: TruncationMode.Fade
                        color: Theme.secondaryHighlightColor
                        text: currentTrack ? currentTrack : "-"
                    }
                }
            }

            onClicked: {
                radioAPI.playStationById(id);
            }

            Component {
                id: itemContextMenu
                ContextMenu {
                    MenuItem {
                        text: qsTr("Remove from favorite")
                        visible: isFavorite()
                        onClicked: {
                            remove()
                        }
                    }
                    MenuItem {
                        text: qsTr("Add to favorite")
                        visible: !isFavorite()
                        onClicked: {
                            var station = stationModel.get(index);
                            station.oneGenre = genresAndTopics.split(",")[0]
                            FavoritesUtils.addFavorite(station)
                        }
                    }
                }
            }

            function remove() {
                remorseAction("Deleteing", function() {
                    var station = stationModel.get(index);
                    FavoritesUtils.removeFavorite(station);
                });
            }

            function isFavorite() {
                var station = stationModel.get(index);
                return FavoritesUtils.isFavorite(station)
            }
        }
    }

    Python {
        id: python

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('../components/python'));
            setHandler('updateStationList', function(stations) {
                window.loading = false;
                populateList(stations)
            });

            importModule('api', function () {});
        }

        function getTop100() {
            window.loading = true;
            call('api.radio.getTopStations', function() {});
        }

        function search(s) {
            window.loading = true;
            call('api.radio.getSearchResults', [s], function() {});
        }

        onError: {
            console.log('python error: ' + traceback);
        }

        onReceived: {
            console.log('got message from python: ' + data);
        }
    }

    Component.onCompleted: {
        if(page.listType === Utils.Top100) {
            python.getTop100();
        }
        else if(page.listType === Utils.Favorites) {
            Utils.updateFavorites(stationModel);
        }
        else if(page.listType === Utils.Search) {
            //
        }

    }

    function populateList(stations) {
        console.log("Number of stations:", stations.length)
        stationModel.clear()

        stations.forEach(function(station) {
            //console.log("STATION:", JSON.stringify(station))
            if(station.playable === "FREE") {
                stationModel.append(station)
            }
        });
    }
}


