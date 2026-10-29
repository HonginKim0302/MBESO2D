function varargout = mbeso_review_update(action, varargin)
% Small update operations shared by production solvers and independent tests.
switch action
    case 'temporal'
        current = varargin{1}; previous_spatial = varargin{2}; iteration = varargin{3};
        if iteration == 1, value = current; else, value = (previous_spatial + current) / 2; end
        varargout{1} = value;
    case 'classify'
        solid = varargin{1}; trace = varargin{2}; old_x = varargin{3};
        old_material = varargin{4}; xmin = varargin{5}; epsilon = varargin{6};
        phase = 2 * ones(size(trace)); phase(~solid) = 0;
        phase(solid & trace >= 0) = 1;
        if epsilon > 0
            band = solid & abs(trace) <= epsilon;
            persistent_mask = band & old_x > xmin & old_material ~= 0;
            phase(persistent_mask) = old_material(persistent_mask);
            phase(band & ~persistent_mask) = 1;
        end
        varargout{1} = phase;
    case 'count'
        value = varargin{1}; mode = varargin{2};
        switch mode
            case 'floor', value = floor(value);
            case 'round', value = round(value);
            case 'ceil', value = ceil(value);
            otherwise, error('Unknown volume rounding.');
        end
        varargout{1} = value;
    case 'sort'
        values = varargin{1}; ids = varargin{2}; total = varargin{3}; review = varargin{4};
        [sorted, order] = sort(values, 'descend');
        if ~strcmp(review.tie_policy, 'index')
            if strcmp(review.tie_policy, 'reverse')
                secondary = -ids(:);
            else
                stream = RandStream('mt19937ar', 'Seed', review.tie_seed);
                priorities = rand(stream, total, 1);
                secondary = priorities(ids(:));
            end
            % The primary column is untouched: only EXACT score ties reorder.
            [~, order] = sortrows([-values(:), secondary], [1 2]);
            sorted = values(order);
        end
        varargout = {sorted, order};
    case 'continue'
        i = varargin{1}; cap = varargin{2}; force = varargin{3};
        reached = varargin{4}; change = varargin{5}; tau = varargin{6};
        first = varargin{7}; post = varargin{8};
        if force, active = true;
        elseif post > 0, active = isnan(first) || i < first + post;
        else, active = ~reached || change > tau;
        end
        varargout{1} = i < cap && active;
    otherwise
        error('Unknown review update action: %s', action);
end
end
