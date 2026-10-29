% SPDX-License-Identifier: GPL-3.0-or-later
function mbeso_enable_physical_contour_datatips(fig)
%MBESO_ENABLE_PHYSICAL_CONTOUR_DATATIPS Report raw values, not color coordinates.
manager = datacursormode(fig);
set(manager,'UpdateFcn',@physical_value_text,'SnapToDataVertex','off');
setappdata(fig,'MBESO_PhysicalContourDatatips',true);
end

function rows = physical_value_text(~,event)
target = get(event,'Target');
position = get(event,'Position');
if ~isgraphics(target,'image') || ~isappdata(target,'MBESO_ElementDatatipData')
    rows = {sprintf('x: %.9g',position(1)),sprintf('y: %.9g',position(2))};
    return
end
data = getappdata(target,'MBESO_ElementDatatipData');
col = min(max(round(position(1)),1),size(data.values,2));
row = min(max(round(position(2)),1),size(data.values,1));
rows = {sprintf('Element x: %d',col),sprintf('Element y: %d',row)};
if isfield(data,'material_map')
    rows{end+1} = sprintf('Assigned material ID: %d',data.material_map(row,col));
end
value = data.values(row,col);
if ~isfinite(value)
    rows{end+1} = 'Value: void element';
    return
end
quantity = 'Value'; unit = '';
if isfield(data,'quantity'), quantity = data.quantity; end
if isfield(data,'unit'), unit = data.unit; end
rows{end+1} = strtrim(sprintf('%s: %.9g %s',quantity,value,unit));
end
