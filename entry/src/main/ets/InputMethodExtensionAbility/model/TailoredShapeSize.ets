export function tailoredShapeSize(isTouching: boolean): string {
    return isTouching ? 'calc(100% - 2vp)' : 'calc(100% - 6vp)';
}
