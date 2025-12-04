<a href="<?php echo e(url('/')); ?>" data-shortcut="home_view" class="logo">
    <?php if(setting('app-logo', '') !== 'none'): ?>
        <img class="logo-image" src="<?php echo e(setting('app-logo', '') === '' ? url('/logo.png') : url(setting('app-logo', ''))); ?>" alt="Logo">
    <?php endif; ?>
    <?php if(setting('app-name-header')): ?>
        <span class="logo-text"><?php echo e(setting('app-name')); ?></span>
    <?php endif; ?>
</a><?php /**PATH /app/www/resources/views/layouts/parts/header-logo.blade.php ENDPATH**/ ?>