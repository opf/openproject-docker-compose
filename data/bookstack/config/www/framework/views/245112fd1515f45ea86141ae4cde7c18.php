<?php if(count(setting('app-footer-links', [])) > 0): ?>
<footer class="print-hidden">
    <?php $__currentLoopData = setting('app-footer-links', []); $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $link): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); ?>
        <a href="<?php echo e($link['url']); ?>" target="_blank" rel="noopener"><?php echo e(strpos($link['label'], 'trans::') === 0 ? trans(str_replace('trans::', '', $link['label'])) : $link['label']); ?></a>
    <?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); ?>
</footer>
<?php endif; ?><?php /**PATH /app/www/resources/views/layouts/parts/footer.blade.php ENDPATH**/ ?>