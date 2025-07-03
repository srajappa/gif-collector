
import os, time, yaml, sys
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service as ChromeService
from webdriver_manager.chrome import ChromeDriverManager

LOCATOR_MAP = {
    "id": By.ID,
    "css": By.CSS_SELECTOR,
    "xpath": By.XPATH
}

WEB_APP_URL = os.getenv("WEB_APP_URL", "https://example.com")
STEPS_FILE  = os.getenv("STEPS_FILE", "/app/scripts/steps.yaml")

def load_steps(path):
    with open(path, "r", encoding="utf-8") as f:
        data = yaml.safe_load(f)
    return data.get("steps", [])

def do_step(driver, step):
    desc = step.get("description", "Unnamed step")
    ltype = step.get("locator_type", "css").lower()
    lval  = step.get("locator_value")
    pause = float(step.get("pause", 2))

    how = LOCATOR_MAP.get(ltype)
    if not how:
        print(f"[WARN] Unsupported locator_type '{ltype}' in step '{desc}'")
        return
    try:
        print(f"→ {desc}")
        el = driver.find_element(how, lval)
        el.click()
    except Exception as e:
        print(f"[WARN] Could not perform step '{desc}': {e}")
    time.sleep(pause)

def main():
    steps = load_steps(STEPS_FILE)
    if not steps:
        print("No steps found in steps.yaml – exiting.")
        sys.exit(1)

    print("Launching Chrome...")
    options = webdriver.ChromeOptions()
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--start-maximized")
    driver = webdriver.Chrome(service=ChromeService(ChromeDriverManager().install()),
                              options=options)
    driver.set_window_size(1280, 720)
    driver.get(WEB_APP_URL)
    time.sleep(3)

    for step in steps:
        do_step(driver, step)

    driver.quit()
    print("Walkthrough complete.")

if __name__ == "__main__":
    main()
