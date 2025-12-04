<?php
    $settingSuffix = setting()->getForCurrentUser('dark-mode-enabled') ? '-dark' : '';
?>
<style>
    :root {
        --color-primary: <?php echo e(setting('app-color' . $settingSuffix)); ?>;
        --color-primary-light: <?php echo e(setting('app-color-light' . $settingSuffix)); ?>;
        --color-link: <?php echo e(setting('link-color' . $settingSuffix)); ?>;
        --color-bookshelf: <?php echo e(setting('bookshelf-color' . $settingSuffix)); ?>;
        --color-book: <?php echo e(setting('book-color' . $settingSuffix)); ?>;
        --color-chapter: <?php echo e(setting('chapter-color' . $settingSuffix)); ?>;
        --color-page: <?php echo e(setting('page-color' . $settingSuffix)); ?>;
        --color-page-draft: <?php echo e(setting('page-draft-color' . $settingSuffix)); ?>;
    }
</style>
<?php /**PATH /app/www/resources/views/layouts/parts/custom-styles.blade.php ENDPATH**/ ?>