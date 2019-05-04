# authoring-admin

Admin application for the course editor written in [Elm](https://elm-lang.org/).

> ### "Project Achilles"
>
> During a battle in the Trojan War in Homer's the  *Illiad*, the river god Scamander, furious over the sight of so many corpses in his waters, overflows his banks in an attempt to drown the responsible party, the great warrior Achilles.  As Achilles is being swept away under the wall of water, he reaches out for safety, grabbing onto the branch of a great elm tree.
>
>We think this is an interesting metaphor for front-end development in JavaScript.

## Related repositories
* [authoring-dev](https://github.com/Simon-Initiative/authoring-dev) - Docker development environment for the course authoring platform
* [authoring-client](https://github.com/Simon-Initiative/authoring-client) - Typescript/React/Redux editing client
* [authoring-server](https://github.com/Simon-Initiative/authoring-server) - Java server, REST API, bridge to OLI
* [authoring-eval](https://github.com/Simon-Initiative/authoring-eval) - Typescript/Node dynamic question evaluation engine

## Getting started

1. Install Elm 0.19 using the binary installer from [elm-lang.org](http://elm-lang.org)

2. Clone this project.
```
git clone https://github.com/Simon-Initiative/achilles.git
```

3. Install it's dependencies
```
npm install
```

4. Install `elm-format`. This is a community Elm project that enforces the Elm coding
standard on every file save.
```
npm install -g elm-format
```

5. Install `elm-live`. This is a community Elm project that provides a hot-reloading server.
```
npm install --global elm elm-live@next
```

6. Install an editor plugin.

7. Update the Keycloak server to allow this new client.
   1. Log into the Keycloak admin console at [dev.local/auth/](http://dev.local/auth/)
   2. Choose the Oli_security realm
   3. Create a new client called "admin_client".
      1. Set root URL and admin URL to be `http://dev.local:7000`
      2. Set the Valid Redirect URL and Web origins to be `*`
   4. Edit the web origins of the "account" client to be `*`
   5. Edit the 'manager' account (under 'users' tab) to add the 'realm-management' client role 'realm-admin'.
   
8. Run the compiler and server.
```
npm run serve
```

9. Open a browser and visit the application at `http://dev.local:7000`.

## License
This software is licensed under the [MIT License](./LICENSE) © 2019 Carnegie Mellon University
