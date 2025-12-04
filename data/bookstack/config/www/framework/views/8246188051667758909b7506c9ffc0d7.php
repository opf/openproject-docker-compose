<?php $popular = app(\BookStack\Entities\Queries\QueryPopular::class); ?>
<?php $__env->startSection('content'); ?>
    <div class="container mt-l">

        <div class="card mb-xl px-l pb-l pt-l">
            <div class="grid half v-center">
                <div>
                    <?php echo $__env->make('errors.parts.not-found-text', [
                        'title' => $message ?? trans('errors.404_page_not_found'),
                        'subtitle' => $subtitle ?? trans('errors.sorry_page_not_found'),
                        'details' => $details ?? trans('errors.sorry_page_not_found_permission_warning'),
                    ], array_diff_key(get_defined_vars(), ['__data' => 1, '__path' => 1]))->render(); ?>
                </div>
                <div class="text-right">
                    <?php if(user()->isGuest()): ?>
                        <a href="<?php echo e(url('/login')); ?>" class="button outline"><?php echo e(trans('auth.log_in')); ?></a>
                    <?php endif; ?>
                    <a href="<?php echo e(url('/')); ?>" class="button outline"><?php echo e(trans('errors.return_home')); ?></a>
                </div>
            </div>

        </div>

        <?php if(setting('app-public') || !user()->isGuest()): ?>
            <div class="grid third gap-xxl">
                <div>
                    <div class="card mb-xl">
                        <h3 class="card-title"><?php echo e(trans('entities.pages_popular')); ?></h3>
                        <div class="px-m">
                            <?php echo $__env->make('entities.list', ['entities' => $popular->run(10, 0, ['page']), 'style' => 'compact'], array_diff_key(get_defined_vars(), ['__data' => 1, '__path' => 1]))->render(); ?>
                        </div>
                    </div>
                </div>
                <div>
                    <div class="card mb-xl">
                        <h3 class="card-title"><?php echo e(trans('entities.books_popular')); ?></h3>
                        <div class="px-m">
                            <?php echo $__env->make('entities.list', ['entities' => $popular->run(10, 0, ['book']), 'style' => 'compact'], array_diff_key(get_defined_vars(), ['__data' => 1, '__path' => 1]))->render(); ?>
                        </div>
                    </div>
                </div>
                <div>
                    <div class="card mb-xl">
                        <h3 class="card-title"><?php echo e(trans('entities.chapters_popular')); ?></h3>
                        <div class="px-m">
                            <?php echo $__env->make('entities.list', ['entities' => $popular->run(10, 0, ['chapter']), 'style' => 'compact'], array_diff_key(get_defined_vars(), ['__data' => 1, '__path' => 1]))->render(); ?>
                        </div>
                    </div>
                </div>
            </div>
        <?php endif; ?>
    </div>

<?php $__env->stopSection(); ?>
<?php echo $__env->make('layouts.simple', array_diff_key(get_defined_vars(), ['__data' => 1, '__path' => 1]))->render(); ?><?php /**PATH /app/www/resources/views/errors/404.blade.php ENDPATH**/ ?>