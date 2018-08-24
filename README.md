# Project Achilles

A course editor admin application written in Elm.

## Why "Project Achilles"?

During a battle in the Trojan War in Homer's the  *Illiad*, the river 
god Scamander, furious over the sight of so many corpses in his waters, overflows
his banks in an attempt to drown the responsible party, the
great warrior Achilles.  As Achilles is being swept away under the great
wall of water, he reaches out for safety, grabbing onto the branch of a great elm tree.

I think this is an interesting metaphor for front-end development in JavaScript.

## Getting started

1. Install Elm 0.19 using the binary installer from [elm-lang.org](http://elm-lang.org)
2. Clone this project.
> git clone https://github.com/Simon-Initiative/achilles.git
3. Install it's dependencies
> npm install
4. Install `elm-format`. This is a community Elm project that enforces the Elm coding
standard on every file save.
> npm install -g elm-format
5. Install `elm-live`. This is a community Elm project that provides a hot-reloading server.
> npm install -g elm-live
6. Install an editor plugin.  The VSCode Elm plugin hasn't yet been updated for Elm 0.19, but
does kinda still work.  I think the Atom and IntelliJ plugins have been updated for 0.19.
7. Update the Keycloak server to allow this new client.
   1. Log into the Keycloak admin console at [dev.local/auth/](http://dev.local/auth/)
   2. Create a new client called "admin_client".
      1. Set root URL and admin URL to be `http://devl.local:7000`
      2. Set the Valid Redirect URL and Web origins to be `*`
   3. Edit the web origins of the "account" client to be `*`
8. Run the compiler and server.
> npm run serve
9. Open a browser and visit the application at `http://dev.local:7000`.



