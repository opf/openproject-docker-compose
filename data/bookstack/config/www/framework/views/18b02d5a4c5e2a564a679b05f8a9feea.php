<?php $headContent = app('BookStack\Theming\CustomHtmlHeadContentProvider'); ?>

<?php if(setting('app-custom-head') && !request()->routeIs('settings.category')): ?>
<!-- Start: custom user content -->
<?php echo $headContent->forWeb(); ?>

<!-- End: custom user content -->
<?php endif; ?><?php /**PATH /app/www/resources/views/layouts/parts/custom-head.blade.php ENDPATH**/ ?>