<?php echo $__env->make('layouts.parts.header-links-start', array_diff_key(get_defined_vars(), ['__data' => 1, '__path' => 1]))->render(); ?>

<?php if(user()->hasAppAccess()): ?>
    <a class="hide-over-l" href="<?php echo e(url('/search')); ?>"><?php echo (new \BookStack\Util\SvgIcon('search'))->toHtml(); ?><?php echo e(trans('common.search')); ?></a>
    <?php if(userCanOnAny(\BookStack\Permissions\Permission::View, \BookStack\Entities\Models\Bookshelf::class) || userCan(\BookStack\Permissions\Permission::BookshelfViewAll) || userCan(\BookStack\Permissions\Permission::BookshelfViewOwn)): ?>
        <a href="<?php echo e(url('/shelves')); ?>"
           data-shortcut="shelves_view"><?php echo (new \BookStack\Util\SvgIcon('bookshelf'))->toHtml(); ?><?php echo e(trans('entities.shelves')); ?></a>
    <?php endif; ?>
    <a href="<?php echo e(url('/books')); ?>" data-shortcut="books_view"><?php echo (new \BookStack\Util\SvgIcon('books'))->toHtml(); ?><?php echo e(trans('entities.books')); ?></a>
    <?php if(!user()->isGuest() && userCan(\BookStack\Permissions\Permission::SettingsManage)): ?>
        <a href="<?php echo e(url('/settings')); ?>"
           data-shortcut="settings_view"><?php echo (new \BookStack\Util\SvgIcon('settings'))->toHtml(); ?><?php echo e(trans('settings.settings')); ?></a>
    <?php endif; ?>
    <?php if(!user()->isGuest() && userCan(\BookStack\Permissions\Permission::UsersManage) && !userCan(\BookStack\Permissions\Permission::SettingsManage)): ?>
        <a href="<?php echo e(url('/settings/users')); ?>"
           data-shortcut="settings_view"><?php echo (new \BookStack\Util\SvgIcon('users'))->toHtml(); ?><?php echo e(trans('settings.users')); ?></a>
    <?php endif; ?>
<?php endif; ?>

<?php if(user()->isGuest()): ?>
    <?php if(setting('registration-enabled') && config('auth.method') === 'standard'): ?>
        <a href="<?php echo e(url('/register')); ?>"><?php echo (new \BookStack\Util\SvgIcon('new-user'))->toHtml(); ?><?php echo e(trans('auth.sign_up')); ?></a>
    <?php endif; ?>
    <a href="<?php echo e(url('/login')); ?>"><?php echo (new \BookStack\Util\SvgIcon('login'))->toHtml(); ?><?php echo e(trans('auth.log_in')); ?></a>
<?php endif; ?><?php /**PATH /app/www/resources/views/layouts/parts/header-links.blade.php ENDPATH**/ ?>