# how to build image: #

```bash
$:~ git clone https://github.com/mohousch/buildsystem.git

cd buildsystem
```

**for first use:**
```bash
$:~ sudo ./prepare-for-bs.sh
```
**machine configuration:**
```bash
$:~ make init
or
$:~ make
```
**build images:**
```bash
$:~ make image-neutrino2
$:~ make image-neutrino
$:~ make image-titan
```

**for more details:**
```bash
$:~ make help
```

**supported boards:**
```bash
$:~ make print-boards
```

* backed image can be found into ~/buildsystem/tufsbox/$(machine)/image.

* tested with:
  debian 8 Jessie, 9 Stretch, 11 Bullseye and 12 Bookworm
  linuxmint 20.1 Ulyssa, 20.2 Uma, 20.3 Una, 21 Vanessa, 21.1 Vera, 21.2 Victoria, LMDE 5 Elsie and LMDE 6 Faye
  Ubuntu 20.04 Focal Fossa, 22.04 Jammy Jellyfish, 22.10 Kinetic Kudu, 23.04 lunar lobster and 23.10 Mantic Minotaur
 
 
