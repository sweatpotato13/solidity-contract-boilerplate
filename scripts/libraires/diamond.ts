/* global ethers */

import { ethers } from "ethers";

export enum FacetCutAction {
    Add = 0,
    Replace = 1,
    Remove = 2,
}

// Interface definition for selector array
interface SelectorExtension extends Array<string> {
    contract: any;
    remove: (functionNames: string[]) => SelectorExtension;
    get: (functionNames: string[]) => SelectorExtension;
}

// get function selectors from ABI
export function getSelectors(contract: any): SelectorExtension {
    // Check if contract has interface with fragments
    if (contract && contract.interface && contract.interface.fragments) {
        // Using ethers v6, we can directly process fragments
        return processFragments(contract);
    }

    // If no interface is found, return empty array with extension methods
    const selectors: string[] = [];
    const selectorsExt = selectors as unknown as SelectorExtension;
    selectorsExt.contract = contract;
    selectorsExt.remove = remove;
    selectorsExt.get = get;
    return selectorsExt;
}

// Process fragments to extract selectors
function processFragments(contract: any): SelectorExtension {
    const fragments = contract.interface.fragments;
    const selectors = fragments
        .filter((fragment: any) => fragment.type === "function")
        .map((fragment: any) => fragment.selector)
        .filter((selector: string) => {
            // Exclude init(bytes) function
            const funcName = contract.interface.getFunction(selector).name;
            return funcName !== "init";
        }) as SelectorExtension;

    selectors.contract = contract;
    selectors.remove = remove;
    selectors.get = get;
    return selectors;
}

// get function selector from function signature
export function getSelector(func: string): string {
    // Add 'function' keyword to the signature if not present
    const fullFunc = func.startsWith("function ") ? func : `function ${func}`;
    const abiInterface = new ethers.Interface([fullFunc]);
    // In ethers v6, use getFunction method
    const funcFragment = abiInterface.getFunction(
        fullFunc.replace("function ", ""),
    );
    if (!funcFragment) {
        throw new Error(`Function not found: ${func}`);
    }
    return funcFragment.selector;
}

// used with getSelectors to remove selectors from an array of selectors
// functionNames argument is an array of function signatures
function remove(
    this: SelectorExtension,
    functionNames: string[],
): SelectorExtension {
    const selectors = this.filter((v) => {
        for (const functionName of functionNames) {
            try {
                const func = this.contract.interface.getFunction(functionName);
                if (v === func.selector) {
                    return false;
                }
            } catch (error) {
                console.warn(`Function not found: ${functionName}`);
            }
        }
        return true;
    }) as SelectorExtension;

    selectors.contract = this.contract;
    selectors.remove = this.remove;
    selectors.get = this.get;
    return selectors;
}

// used with getSelectors to get selectors from an array of selectors
// functionNames argument is an array of function signatures
function get(
    this: SelectorExtension,
    functionNames: string[],
): SelectorExtension {
    const selectors = this.filter((v) => {
        for (const functionName of functionNames) {
            try {
                const func = this.contract.interface.getFunction(functionName);
                if (v === func.selector) {
                    return true;
                }
            } catch (error) {
                console.warn(`Function not found: ${functionName}`);
            }
        }
        return false;
    }) as SelectorExtension;

    selectors.contract = this.contract;
    selectors.remove = this.remove;
    selectors.get = this.get;
    return selectors;
}

// remove selectors using an array of signatures
export function removeSelectors(
    selectors: string[],
    signatures: string[],
): string[] {
    // Add 'function' keyword to each signature if not present
    const fullSignatures = signatures.map((v: string) =>
        v.startsWith("function ") ? v : `function ${v}`,
    );

    const iface = new ethers.Interface(fullSignatures);

    // In ethers v6, use getFunction to get function and extract selector
    const removeSelectors = signatures
        .map((sig) => {
            const functionName =
                sig.indexOf("(") > -1
                    ? sig.substring(0, sig.indexOf("("))
                    : sig;
            const func = iface.getFunction(functionName);
            return func ? func.selector : "";
        })
        .filter(Boolean);

    selectors = selectors.filter((v: string) => !removeSelectors.includes(v));
    return selectors;
}

// find a particular address position in the return value of diamondLoupeFacet.facets()
export function findAddressPositionInFacets(
    facetAddress: string,
    facets: Array<{ facetAddress: string }>,
): number | undefined {
    for (let i = 0; i < facets.length; i++) {
        if (facets[i].facetAddress === facetAddress) {
            return i;
        }
    }
    return undefined;
}
