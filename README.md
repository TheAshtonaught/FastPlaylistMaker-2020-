# Playlist Cheetah

**Playlist Cheetah** allows users to create playlist simply by swiping left to add songs or swiping right to skip them. When the app opens it grabs the users music library which includes songs on their device and in their iCloud library. After playlists are created they're persisted to the user's device through Apple's Core Data library.

![Alt text](https://cloud.githubusercontent.com/assets/20712747/23116341/bf40dcf2-f70f-11e6-944f-4d5f2d6affb2.jpg)

## Apple Music Search View(Requires Apple Music Access)

Uses the Itunes Api to allow users to search and add songs from Apple Music if they are a member.

![Alt text](https://cloud.githubusercontent.com/assets/20712747/23116354/c9945490-f70f-11e6-89fd-7e0a7794ed32.jpg)

## Playlist View
Shows the users persisted Playlist

![Alt text](![playlisttablescreenshot](https://cloud.githubusercontent.com/assets/20712747/23855239/f0ee2a34-07c2-11e7-8452-c4c0a2bf4d06.PNG))

## Song List View
songs that compose a playlist

![Alt text](https://cloud.githubusercontent.com/assets/20712747/23116353/c76b3396-f70f-11e6-97a4-50e062991204.jpg)

**Pressing Play** opens the playlist in the native music app.

## Requirements
* Run on physical device Xcode throws weird errors when trying to run on simulator because it does not have the Native music app
* Some features require an Apple Music account

## Future Versions
* Spotify Support
* Machine learning to improve which song appears next
