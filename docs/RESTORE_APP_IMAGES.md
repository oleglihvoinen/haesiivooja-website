# Recover original HaeSiivooja app screenshots from WordPress

The production server retained the old WordPress installation in `/var/www/html`. Changing Apache's website document root to Astro does **not** erase the WordPress media library. The original public images normally remain in `/var/www/html/wp-content/uploads/` (or a nested `wordpress/wp-content/uploads/` directory).

The new site deliberately references only original app screenshot files, not random stock imagery. A VPS-only importer copies relevant original screenshots to the Astro project's `public/app-screenshots/` folder and builds a local media manifest. The original media are never altered. **These image files are not added to public GitHub automatically.**

## Run in an SSH shell on the VPS

```bash
cd /opt/haesiivooja-website
git pull --ff-only
sudo apt-get install -y python3-pil
python3 scripts/restore-wordpress-app-images.py --scan
```

**Review candidate image filenames** in the scan output before importing to avoid accidentally publishing an unrelated portrait or photo. The selector prefers real phone-shaped screenshots and filenames containing `screenshot`, `app`, `mobiili`, `ios` and `android`.

If the candidates are correct:

```bash
python3 scripts/restore-wordpress-app-images.py --apply
npm run check
npm run predeploy
bash ops/deploy-from-vps.sh "$PWD" prepare
```

If the original images do not have distinctive filenames, list them and explicitly select the correct files:

```bash
find /var/www/html/wp-content/uploads /var/www/html/wordpress/wp-content/uploads -type f \
  \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) \
  2>/dev/null | sort | tail -100

python3 scripts/restore-wordpress-app-images.py --scan --select '*screenshot*,*app*,*mobiili*'
```

To target a known media folder, pass `--source /path/to/wp-content/uploads`. To choose specific originals, use `--select 'file1.png,file2.png'`. For accuracy, do **not** run `--apply` until the selected filenames are those of the original app screenshots.

## Deploy the release

Activate the prepared release using the existing Apache symlink switch, without removing `/var/www/html`. The new build will include the copied screenshots. On the finished website check the homepage's real mobile screenshots and the app-gallery section in both languages.

After a later `git pull`, images and the local manifest remain in place because these paths are gitignored. Each subsequent Astro build will include them. The page falls back to its current illustrative device card until originals have been imported.

## SEO, privacy, and quality

Only publish screenshots already intended for public display. If any original screenshot contains a private user's name, address, telephone number or payment details, do not import it without redaction. Each screenshot gets a neutral alt description; edit the local manifest's text for meaningful, screen-specific captions after reviewing the images.
