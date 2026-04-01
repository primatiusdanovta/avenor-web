const fallbackPrefix = '/administrator';

const normalizePrefix = (value) => {
    const raw = typeof value === 'string' && value.trim() !== '' ? value.trim() : fallbackPrefix;
    const withLeadingSlash = raw.startsWith('/') ? raw : `/${raw}`;
    return withLeadingSlash.replace(/\/+$/, '');
};

export const adminPrefix = () => normalizePrefix(window.AVENOR_ADMIN_PREFIX);

export const adminUrl = (path = '') => {
    const normalizedPath = String(path || '').trim();

    if (normalizedPath === '' || normalizedPath === '/') {
        return adminPrefix();
    }

    if (normalizedPath.startsWith('http://') || normalizedPath.startsWith('https://')) {
        return normalizedPath;
    }

    return `${adminPrefix()}${normalizedPath.startsWith('/') ? normalizedPath : `/${normalizedPath}`}`;
};
