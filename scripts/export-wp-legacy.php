<?php
/** Run from the WordPress installation root: wp eval-file /path/to/export-wp-legacy.php > legacy-pages.json
 *  Exports only publicly published legal/support pages, not WP user records or secrets.
 */
$needed = ['terms-of-service', 'privacy-policy', 'accessibility-statement', 'app-guide', 'our-story', 'cleaner'];
$out = [];
foreach ($needed as $slug) {
    $p = get_page_by_path($slug, OBJECT, 'page');
    if (!$p || $p->post_status !== 'publish') continue;
    $content = apply_filters('the_content', $p->post_content);
    // Remove scripts, forms and potentially unsafe tags from imported HTML.
    $content = wp_kses_post($content);
    $text = trim(wp_strip_all_tags($content));
    if (mb_strlen($text) < 80) continue;
    $out[] = [
        'slug' => $slug,
        'title' => get_the_title($p->ID),
        'description' => wp_trim_words($text, 24, '…'),
        'content' => $content,
    ];
}
echo wp_json_encode($out, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
