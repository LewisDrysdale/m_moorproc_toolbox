function m_write_header(ncfile,h)

% write header to mstar file (global attributes)
% assume that the calling program already has checked it is suitable for writing, 
% and the openflag set to W
% don't reset the MEXEC.status of the openflag

if nargin ~= 2
    error('Must supply precisely two arguments to m_write_header');
end

hatt = m_default_attributes;
hatt_names = fieldnames(hatt);

for k = 1:length(hatt_names)
    gattnam = hatt_names{k};
    cmd = ['gattval = h.' gattnam ';'];
    eval(cmd);
    gattval;
    nc_attput(ncfile.name,nc_global,gattnam,gattval);
end