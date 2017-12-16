
# Building
This image has automatic build enabled at Docker Hub.
The automatic build uses the `hooks/build` file, change that file to change build arguments such as MediaWiki version.

For building locally you can use `docker-compose build`.

# Testing
There is a `docker-compose.yml` file in the root of this project that is suitable for testing.

To start the testing stack just run `docker-compose up -d` in the project root.
If you are not running Linux you can use Vagrant, see below.

To delete the test stack run `docker-compose down` and `rm -R /srv/wiki` (assuming you are using the test `docker-compose` file).

## Testing with vagrant
First install the `vagrant-docker-compose` plugin if you don't already have it.
```bash
vagrant plugin install vagrant-docker-compose
```

```bash
vagrant up
vagrant ssh

cd /vagrant
docker-compose up -d
```
