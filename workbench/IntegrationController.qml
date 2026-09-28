import QtQuick

QtObject {
    id: controller

    property var _armed: ({})
    property var _reached: ({})
    property var _animations: ({})
    signal checkpointReached(string name)
    signal checkpointContinued(string name)

    function arm(name: string): var {
        const key = String(name ?? "");
        if (key === "")
            return { ok: false, error: "checkpoint name is required" };
        if (controller._armed[key] === true || controller._reached[key] === true)
            return { ok: false, error: "checkpoint '" + key + "' is already armed or reached" };
        const armed = Object.assign({}, controller._armed);
        armed[key] = true;
        controller._armed = armed;
        return { ok: true };
    }

    function isArmed(name: string): bool {
        return controller._armed[String(name ?? "")] === true;
    }

    function hasReached(name: string): bool {
        return controller._reached[String(name ?? "")] === true;
    }

    function activeAnimation(name: string): var {
        return controller._animations[String(name ?? "")];
    }

    function checkpoint(name: string, animation: var): var {
        const key = String(name ?? "");
        if (controller._armed[key] !== true)
            return { ok: true, reached: false };
        if (controller._reached[key] === true)
            return { ok: false, error: "checkpoint '" + key + "' was already reached" };
        if (!animation || typeof animation.pause !== "function")
            return { ok: false, error: "checkpoint '" + key + "' did not receive a pausable animation" };
        const reached = Object.assign({}, controller._reached);
        const animations = Object.assign({}, controller._animations);
        reached[key] = true;
        animations[key] = animation;
        controller._reached = reached;
        controller._animations = animations;
        animation.pause();
        controller.checkpointReached(key);
        return { ok: true, reached: true };
    }

    function continueCheckpoint(name: string): var {
        const key = String(name ?? "");
        if (controller._reached[key] !== true)
            return { ok: false, error: "checkpoint '" + key + "' has not been reached" };
        const animation = controller._animations[key];
        if (!animation || typeof animation.resume !== "function")
            return { ok: false, error: "checkpoint '" + key + "' has no stored animation" };
        animation.resume();
        controller.checkpointContinued(key);
        const armed = Object.assign({}, controller._armed);
        const reached = Object.assign({}, controller._reached);
        const animations = Object.assign({}, controller._animations);
        delete armed[key];
        delete reached[key];
        delete animations[key];
        controller._armed = armed;
        controller._reached = reached;
        controller._animations = animations;
        return { ok: true };
    }

    function reset(): void {
        const names = Object.keys(controller._animations);
        for (let i = 0; i < names.length; i++) {
            const animation = controller._animations[names[i]];
            if (animation && typeof animation.stop === "function")
                animation.stop();
        }
        controller._armed = {};
        controller._reached = {};
        controller._animations = {};
    }
}
