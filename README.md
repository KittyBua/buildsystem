simple buildsystem to build NeutrinoNG images for settop boxes. 

# how to build image: #

```bash
$:~ git clone https://github.com/mohousch/buildsystem.git

cd buildsystem
```

**for first use:**
```bash
$:~ sudo bash prepare-for-bs.sh
```
**machine configuration:**
```bash
$:~ make
or
$:~ make init
```
**build images:**
```bash
$:~ make image-neutrino2
```
or

```bash
$:~ make image-neutrino
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

