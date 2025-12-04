<?php $__env->startSection('content'); ?>

    <div class="flex-fill flex">
        <div class="content flex">
            <div id="main-content" class="scroll-body">
                <?php echo $__env->yieldContent('body'); ?>
            </div>
        </div>
    </div>

<?php $__env->stopSection(); ?>

<?php echo $__env->make('layouts.base', array_diff_key(get_defined_vars(), ['__data' => 1, '__path' => 1]))->render(); ?><?php /**PATH /app/www/resources/views/layouts/simple.blade.php ENDPATH**/ ?>