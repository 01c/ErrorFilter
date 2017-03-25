# ErrorFilter v0.9
A simple World of Warcraft 1.12 AddOn. 

Filters out <strong>specified or all</strong> error messages, such as "Not enough rage".

Useful for PvP/PvE encounters when you want to keep a clean screen while spamming abilities.

Based on RogueSpam by Allara.

<h2>Instructions</h2>
Download: https://github.com/01c/ErrorFilter/archive/master.zip

Extract to <strong>World of Warcraft\Interface\AddOns</strong> and rename folder to <strong>ErrorFilter</strong>.

Type <em>/errorfilter</em> or <em>/ef</em> ingame for help.

<h4>Usage</h4>
/{<strong>errorfilter</strong> | <strong>ef</strong>} {<strong>reset</strong> | <strong>enabled</strong> | <strong>all</strong> | <strong>list</strong> | <strong>add</strong> | <strong>remove</strong>}
<ul>
  <li><strong>reset:</strong> Reset all options to default settings.</li>
  <li><strong>enabled:</strong> Toggle functionality.</li>
  <li><strong>all:</strong> Toggle filtering all messages, ignoring list.</li>
  <li><strong>list:</strong> Shows the current filters and their ID number.</li>
  <li><strong>add #message:</strong> Adds #message to the filter list.</li>
  <li><strong>remove #id:</strong> Removes the message #id from the filter list.</li>
</ul>

<h4>Default filters</h4>
<ul>
  <li>"Ability is not ready yet."</li>
  <li>"You are too far away!"</li>
  <li>"Out of range."</li>
  <li>"Spell is not ready yet."</li>
  <li>"Not enough energy"</li>
  <li>"Not enough rage"</li>
  <li>"Not enough mana"</li>
  <li>"There is nothing to attack."</li>
  <li>"That ability requires combo points"</li>
  <li>"Your target is dead"</li>
  <li>"Another action is in progress"</li>
</ul>
