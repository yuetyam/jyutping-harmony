export const enum HapticType {
    Soft = 1,
    Hard = 2,
    Sharp = 3,
    Success = 4,
    Failure = 5,
    Warning = 6,
}

export namespace HapticEffectId {
    export function of(type: HapticType): string {
        switch (type) {
            case HapticType.Soft: return "haptic.effect.soft";
            case HapticType.Hard: return "haptic.effect.hard";
            case HapticType.Sharp: return "haptic.effect.sharp";
            case HapticType.Success: return "haptic.notice.success";
            case HapticType.Failure: return "haptic.notice.fail";
            case HapticType.Warning: return "haptic.notice.warning";
        }
    }
}
