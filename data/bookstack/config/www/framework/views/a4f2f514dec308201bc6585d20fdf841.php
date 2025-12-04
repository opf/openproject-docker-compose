<div component="notification"
     option:notification:type="success"
     option:notification:auto-hide="true"
     option:notification:show="<?php echo e(session()->has('success') ? 'true' : 'false'); ?>"
     style="display: none;"
     class="notification pos"
     role="alert">
    <?php echo (new \BookStack\Util\SvgIcon('check-circle'))->toHtml(); ?> <span><?php if(session()->has('success')): ?><?php echo nl2br(htmlentities(session()->get('success'))); ?><?php endif; ?></span><div class="dismiss"><?php echo (new \BookStack\Util\SvgIcon('close'))->toHtml(); ?></div>
</div>

<div component="notification"
     option:notification:type="warning"
     option:notification:auto-hide="false"
     option:notification:show="<?php echo e(session()->has('warning') ? 'true' : 'false'); ?>"
     style="display: none;"
     class="notification warning"
     role="alert">
    <?php echo (new \BookStack\Util\SvgIcon('info'))->toHtml(); ?> <span><?php if(session()->has('warning')): ?><?php echo nl2br(htmlentities(session()->get('warning'))); ?><?php endif; ?></span><div class="dismiss"><?php echo (new \BookStack\Util\SvgIcon('close'))->toHtml(); ?></div>
</div>

<div component="notification"
     option:notification:type="error"
     option:notification:auto-hide="false"
     option:notification:show="<?php echo e(session()->has('error') ? 'true' : 'false'); ?>"
     style="display: none;"
     class="notification neg"
     role="alert">
    <?php echo (new \BookStack\Util\SvgIcon('danger'))->toHtml(); ?> <span><?php if(session()->has('error')): ?><?php echo nl2br(htmlentities(session()->get('error'))); ?><?php endif; ?></span><div class="dismiss"><?php echo (new \BookStack\Util\SvgIcon('close'))->toHtml(); ?></div>
</div><?php /**PATH /app/www/resources/views/layouts/parts/notifications.blade.php ENDPATH**/ ?>