function review = mbeso_review_options(options)
% Explicit numerical variants; defaults preserve the submitted update rule.
review = struct('diagnostic_fields', false, 'stress_measure', 'center', ...
    'volume_rounding', 'floor', 'tie_policy', 'index', 'tie_seed', 1729, ...
    'material_zero_tolerance', 0, 'continue_after_convergence', 0);
names = fieldnames(review);
for k = 1:numel(names)
    if isfield(options,names{k}) && ~isempty(options.(names{k}))
        review.(names{k}) = options.(names{k});
    end
end
review.stress_measure = validatestring(review.stress_measure, {'center','gauss_mean_vm','gauss_max_vm'});
review.volume_rounding = validatestring(review.volume_rounding, {'floor','round','ceil'});
review.tie_policy = validatestring(review.tie_policy, {'index','reverse','fixed_random'});
validateattributes(review.tie_seed, {'numeric'}, {'scalar','integer','nonnegative','finite'});
validateattributes(review.material_zero_tolerance, {'numeric'}, {'scalar','nonnegative','finite'});
validateattributes(review.continue_after_convergence, {'numeric'}, {'scalar','integer','nonnegative','finite'});
validateattributes(review.diagnostic_fields, {'logical','numeric'}, {'scalar'});
review.diagnostic_fields = logical(review.diagnostic_fields);
end
